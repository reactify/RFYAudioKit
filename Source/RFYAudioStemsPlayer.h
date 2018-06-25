//
//  RFYAudioStemsPlayer.h
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 14/04/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import "RFYAudioPlayable.h"
#import "RFYAudioFilePlayer.h"

// This object currently assumes that all stems are of same length

@class RFYAudioFilePlayer;

@interface RFYAudioStemsPlayer : NSObject <RFYAudioPlayable>

// The underlying file players
@property (nonatomic, readonly) NSArray<RFYAudioFilePlayer *>* players;

@property (nonatomic, weak) id<RFYAudioFilePlayerDelegate> delegate;

// TODO: Report errors
- (instancetype)initWithFiles:(NSArray<NSURL *>*)urls error:(NSError **)outError;

// Calls stop: before loading a new file
- (BOOL)loadFiles:(NSArray<NSURL *>*)files;

@end
