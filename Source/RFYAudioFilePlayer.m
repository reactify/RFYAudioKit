//
//  RFYAudioFilePlayer.m
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 02/06/2017.
//  Copyright © 2017 Reactify. All rights reserved.
//

#import "TPCircularBuffer+AudioBufferList.h"
#import "RFYAudioUtils.h"
#import "RFYAudioFilePlayer.h"

static const UInt32 kPlaybackBufferLengthInFrames = 8192;

#pragma mark - RFYAudioFilePlayer

@interface RFYAudioFilePlayer () {
  ExtAudioFileRef _file;
  TPCircularBuffer _buffer;
  SInt64 _totalFrames;
  AudioStreamBasicDescription _audioFormat;
}
@property (nonatomic) NSThread *producerThread;
@property (nonatomic, readwrite) BOOL isPlaying;
@end

@implementation RFYAudioFilePlayer

@synthesize isPlaying = _isPlaying;

//--------------------------------------------------------------
- (void)dealloc {
  if ( _isPlaying ) {
    [self stop];
  }
  TPCircularBufferCleanup( &_buffer );
}

//--------------------------------------------------------------
- (instancetype)initWithFile:(NSURL *)url error:(NSError * __autoreleasing *)outError {
  if ( !(self = [super init]) ) {
    return nil;
  }
  
  _volume = 1.f;
  
  _audioFormat = nonInterleavedFloatStereo();
  
  // Init the playback buffer
  size_t frameSize = _audioFormat.mBytesPerFrame * _audioFormat.mChannelsPerFrame;
  size_t audioByteCount = kPlaybackBufferLengthInFrames * frameSize;
  size_t controlDataByteCount = (sizeof(AudioBufferList) + sizeof(AudioBuffer)) * 30;
  TPCircularBufferInit( &_buffer, (UInt32)(audioByteCount + controlDataByteCount) );
  
  if ( ![self loadFile:url] ) {
    return nil;
  }
  
  return self;
}

//--------------------------------------------------------------
- (BOOL)loadFile:(NSURL *)file {
  [self stop];
  
  if (! checkResult(ExtAudioFileOpenURL((__bridge CFURLRef)file, &_file), "Error opening file") ) {
    return NO;
  }
  
  if (! checkResult(ExtAudioFileSetProperty(_file,
                                            kExtAudioFileProperty_ClientDataFormat,
                                            sizeof(_audioFormat),
                                            &_audioFormat),
                    "ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat)") )
  {
    ExtAudioFileDispose(_file);
    return NO;
  }
  
  _totalFrames = ({
    SInt64 fileSize;
    UInt32 propertySize = sizeof(fileSize);
    checkResult( ExtAudioFileGetProperty(_file, kExtAudioFileProperty_FileLengthFrames , &propertySize, &fileSize),
                "Error getting file size");
    
    AudioStreamBasicDescription fileFormat;
    propertySize = sizeof(fileFormat);
    checkResult( ExtAudioFileGetProperty(_file, kExtAudioFileProperty_FileDataFormat, &propertySize, &fileFormat),
                "Error getting file format");
    
    (SInt64)((double)fileSize * (_audioFormat.mSampleRate / fileFormat.mSampleRate));
  });
  
  return YES;
}

//--------------------------------------------------------------
- (void)play {
  if ( !_producerThread ) {
    _producerThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(__produceAudio)
                                                object:nil];
    [_producerThread start];
  }
  
  self.isPlaying = YES;
}

//--------------------------------------------------------------
- (void)pause {
  self.isPlaying = NO;
}

//--------------------------------------------------------------
- (void)stop {
  [self pause];
  
  [_producerThread cancel];
  _producerThread = nil;
  
  if ( _file != NULL ) {
    ExtAudioFileDispose( _file );
    _file = NULL;
  }
  
  TPCircularBufferClear(&_buffer);
}

//--------------------------------------------------------------
- (NSTimeInterval)duration {
  if ( _file == NULL ) {
    return 0.0;
  }
  return (double)_totalFrames / _audioFormat.mSampleRate;
}

//--------------------------------------------------------------
- (void)setCurrentTime:(NSTimeInterval)seconds {
  if ( _file != NULL ) {
    SInt64 frames = (SInt64)(seconds * _audioFormat.mSampleRate);
    checkResult( ExtAudioFileSeek(_file, frames), "Error seeking" );
  }
}

- (double)currentTime {
  return (double)[self __elapsedFrames] / _audioFormat.mSampleRate;
}

//--------------------------------------------------------------
- (int)process:(AudioBufferList *)buffer length:(UInt32)frames {
  if ( !_isPlaying ) {
    return 0;
  }
  
  UInt32 toRead = TPCircularBufferPeek(&_buffer, NULL, &_audioFormat);
  if ( toRead > frames ) toRead = frames;
  if ( toRead > 0 ) {
    // Read from playback buffer
    TPCircularBufferDequeueBufferListFrames( &_buffer, &toRead, buffer, NULL, &_audioFormat );
    
    if ( _volume < 1.f ) {
      AudioBufferListMultiply(buffer, toRead, _volume);
    }
  }
  else if ( toRead == 0 && [self __elapsedFrames] >= _totalFrames ) {
    [self stop];
    dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), ^{
      [self->_delegate audioFilePlayerDidFinishPlayback:self];
    });
  }
  return (int)toRead;
}

//--------------------------------------------------------------
- (long long)__elapsedFrames {
  if ( _file == NULL ) {
    return 0;
  }
  SInt64 frames = 0;
  checkResult( ExtAudioFileTell(_file, &frames), "Error getting elapsed frames" );
  return frames;
}

//--------------------------------------------------------------
- (void)__produceAudio {
  while ( ![NSThread currentThread].isCancelled ) {
    while ( 1 ) {
      static UInt32 frames = 1024;
      
      AudioBufferList *bufferList = TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(&_buffer, &_audioFormat, frames, NULL);
      if ( !bufferList ) {
        break;
      }
      
      // Read from file
      UInt32 readFrames = frames;
      checkResult( ExtAudioFileRead(_file, &readFrames, bufferList), "Error on ExtAudioFileRead" );
      
      if ( readFrames == 0 ) { // EOF
        break;
      }
      
      if ( readFrames < frames ) {
        // We reached the end; update the audio buffer list to report the number of frames remaining
        for ( UInt32 i = 0; i < bufferList->mNumberBuffers; i++ ) {
          bufferList->mBuffers[i].mDataByteSize = readFrames * _audioFormat.mBytesPerFrame;
        }
      }
      
      // Notify delegate of audio read, for optional processing
      [_delegate audioFilePlayer:self willQueueAudio:bufferList];
      
      TPCircularBufferProduceAudioBufferList(&_buffer, NULL);
      
      if ( _file == NULL ) {
        break;
      }
    }
    
    if ( _file == NULL ) {
      break;
    }
    
    usleep(10000);
  }
}

@end
