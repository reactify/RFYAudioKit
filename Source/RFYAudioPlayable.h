//
//  RFYAudioPlayable.h
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 14/04/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import "RFYAudioProducer.h"

@protocol RFYAudioPlayable <RFYAudioProducer>
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) double duration;
- (void)play;
- (void)pause;
- (void)stop;
@end
