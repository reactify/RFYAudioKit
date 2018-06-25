//
//  RFYAudioQueuePlayer.m
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 29/01/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import <RFYAppKit/RFYUtils.h>
#import <RFYAppKit/NSArray+RFYUtilities.h>
#import "RFYAudioQueuePlayer.h"

@interface RFYAudioQueuePlayer() <RFYAudioFilePlayerDelegate> {
  id <RFYAudioQueuePlayerDelegate> _delegate;
}
@property (nonatomic, readwrite) NSUInteger currentIndex;
@property (nonatomic) NSMutableArray<NSURL *>* mFiles;
@end

@implementation RFYAudioQueuePlayer

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
  BOOL automatic = NO;
  if ( [theKey isEqualToString:@"isPlaying"] ) {
    automatic = NO;
  }
  else {
    automatic = [super automaticallyNotifiesObserversForKey:theKey];
  }
  return automatic;
}

- (instancetype)initWithFile:(NSURL *)file error:(NSError * __autoreleasing *)outError {
  return [self initWithFiles:@[file] error:outError];
}

- (instancetype)initWithFiles:(NSArray<NSURL *> *)files error:(NSError * __autoreleasing *)outError {
  if ( !files || files.count == 0 ) {
    return nil;
  }
  
  self = [super initWithFile:files.firstObject error:outError];
  if ( self ) {
    _mFiles = [files mutableCopy];
    _currentIndex = 0;
    [super setDelegate:self];
  }
  return self;
}

- (void)setIsPlaying:(BOOL)isPlaying {
  // Here we override the 'isPlaying' property to avoid
  // sending out a playback state change when moving to
  // next file in the queue.
  //
  // e.g. Without this, when advancing to a new track
  // 'isPlaying' will be set to 'NO' when current track
  // stops and then 'YES' when new track starts.
  //
  // This way, it stays at 'isPlaying' unless stopped manually.
  
  if ( isPlaying == _isPlaying ) {
    return;
  }
  
  if ( [self __eof] && ![self __endOfQueue] ) {
    return;
  }
  
  [self willChangeValueForKey:@"isPlaying"];
  _isPlaying = isPlaying;
  [self didChangeValueForKey:@"isPlaying"];
}

- (NSURL *)currentFile {
  return [_mFiles rfy_safeObjectAtIndex:_currentIndex];
}

- (NSArray<NSURL *> *)files {
  return [_mFiles copy];
}

- (void)setDelegate:(id <RFYAudioQueuePlayerDelegate>)delegate {
  _delegate = delegate;
}

- (id <RFYAudioQueuePlayerDelegate>)delegate {
  return _delegate;
}

- (void)skipToPreviousItem {
  [self skipToFileAtIndex:--_currentIndex];
}

- (void)skipToNextItem {
  [self skipToFileAtIndex:++_currentIndex];
}

- (void)skipToFileAtIndex:(NSUInteger)index {
  BOOL wasPlaying = self.isPlaying;
  if ( wasPlaying ) {
    _isPlaying = NO;
  }
  
  if ( index >= _mFiles.count ) {
    // End of queue
    _currentIndex = NSNotFound;
    
    [self stop];
    [_delegate audioQueuePlayerDidFinishPlayback:self];
    return;
  }
  
  _currentIndex = index;
  
  let file = [_mFiles rfy_safeObjectAtIndex:_currentIndex];
  [self loadFile:file];
  if ( wasPlaying ) {
    _isPlaying = YES;
  }
  [self play];
  
  [_delegate audioQueuePlayer:self didAdvanceToFile:file];
}

- (void)audioFilePlayer:(RFYAudioFilePlayer *)player willQueueAudio:(AudioBufferList *)audio {
  [_delegate audioQueuePlayer:self willQueueAudio:audio];
}

- (void)audioFilePlayerDidFinishPlayback:(RFYAudioFilePlayer *)player {
  [self skipToNextItem];
}

// End of file
- (BOOL)__eof {
  return self.currentTime == self.duration;
}

- (BOOL)__endOfQueue {
  return self.currentIndex >= self.mFiles.count;
}

@end
