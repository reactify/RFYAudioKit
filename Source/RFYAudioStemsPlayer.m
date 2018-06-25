//
//  RFYAudioStemsPlayer.m
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 14/04/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <RFYAppKit/NSArray+RFYUtilities.h>
#import "RFYAudioUtils.h"
#import "RFYAudioStemsPlayer.h"

static void * RFYStemsPlayerContext = &RFYStemsPlayerContext;

@interface RFYAudioStemsPlayer() {
  AudioBufferList* _scratchBuffer;
}
@property (nonatomic, readwrite) BOOL isPlaying;
@property (nonatomic, readwrite) NSArray<RFYAudioFilePlayer *>* players;
@end

@implementation RFYAudioStemsPlayer

- (void)dealloc {
  // TODO: FreeAudioBufferList
  [self removePlaybackObserver];
}

- (instancetype)initWithFiles:(NSArray<NSURL *>*)urls error:(NSError * __autoreleasing *)outError {
  self = [super init];
  if ( self ) {
    [self loadFiles:urls];
  }
  return self;
}

- (BOOL)loadFiles:(NSArray<NSURL *>*)files {
  self.players = [files map:^id(NSURL* url) {
    return [[RFYAudioFilePlayer alloc] initWithFile:url error:nil];
  }];
  
  [self.players makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
  [self addPlaybackObserver];
  
  _scratchBuffer = InitAudioBufferList(nonInterleavedFloatStereo(), 2048);
  
  return YES; // Check for nil player objects
}

- (NSTimeInterval)duration {
  return self.players.firstObject.duration;
}

- (void)setCurrentTime:(NSTimeInterval)seconds {
  [_players each:^(id player) {
    [player setCurrentTime:seconds];
  }];
}

- (double)currentTime {
 return self.players.firstObject.currentTime;
}

- (BOOL)isPlaying {
  return self.players.firstObject.isPlaying;
}

- (void)play {
  [self.players makeObjectsPerformSelector:@selector(play)];
}

- (void)pause {
  [self.players makeObjectsPerformSelector:@selector(pause)];
}

- (void)stop {
  [self.players makeObjectsPerformSelector:@selector(stop)];
}

- (int)process:(AudioBufferList *)buffer length:(UInt32)frames {
  if ( !_players || _players.count == 0 || !_isPlaying ) {
    return 0;
  }
  
  int readFrames = 0;
  for ( RFYAudioFilePlayer* player in _players ) {
    readFrames += [player process:_scratchBuffer length:frames];
    
    for ( UInt32 i = 0; i < buffer->mNumberBuffers; i++ ) {
      vDSP_vadd((float*)_scratchBuffer->mBuffers[i].mData, 1,
                (float*)buffer->mBuffers[i].mData, 1,
                (float*)buffer->mBuffers[i].mData, 1,
                frames);
    }
  }
  return readFrames / (int)_players.count;
}

- (void)audioFilePlayer:(RFYAudioFilePlayer *)player willQueueAudio:(AudioBufferList *)audio {
  // TODO
}

- (void)audioFilePlayerDidFinishPlayback:(RFYAudioFilePlayer *)player {
  if ( player == self.players.firstObject ) {
    [self.delegate audioFilePlayerDidFinishPlayback:self];
  }
}

- (void)addPlaybackObserver {
  [self removePlaybackObserver];
  [self.players.firstObject addObserver:self
                             forKeyPath:@"isPlaying"
                                options:NSKeyValueObservingOptionNew
                                context:RFYStemsPlayerContext];
}

- (void)removePlaybackObserver {
  rfy_safelyRemoveObserver(_players.firstObject, self, @"isPlaying", RFYStemsPlayerContext);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  self.isPlaying = self.players.firstObject.isPlaying;
}

@end
