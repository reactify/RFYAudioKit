//
//  RFYAudioQueuePlayer.h
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 29/01/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import "RFYAudioFilePlayer.h"

@class RFYAudioQueuePlayer;

@protocol RFYAudioQueuePlayerDelegate <NSObject>
// Notify delegate of audio read, for optional processing
// Not called from a realtime thread
- (void)audioQueuePlayer:(RFYAudioQueuePlayer *)player willQueueAudio:(AudioBufferList *)audio;
- (void)audioQueuePlayer:(RFYAudioQueuePlayer *)player didAdvanceToFile:(NSURL *)file;
- (void)audioQueuePlayerDidFinishPlayback:(RFYAudioQueuePlayer *)player;
@end

@interface RFYAudioQueuePlayer : RFYAudioFilePlayer

@property (nonatomic,readonly) NSUInteger currentIndex;

@property (nonatomic,readonly) NSURL* currentFile;

@property (nonatomic,readonly) NSArray<NSURL *>* files;

- (instancetype)initWithFiles:(NSArray<NSURL *> *)files error:(NSError **)outError;

- (void)setDelegate:(id <RFYAudioQueuePlayerDelegate>)delegate;

- (id <RFYAudioQueuePlayerDelegate>)delegate;

// Stops playback if end of queue is reached
- (void)skipToPreviousItem;

- (void)skipToNextItem;

// Stops playback if index if out of bounds
- (void)skipToFileAtIndex:(NSUInteger)index;

@end
