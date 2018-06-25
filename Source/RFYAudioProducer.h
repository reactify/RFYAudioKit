//
//  RFYAudioProducer.h
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 14/04/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#import <CoreAudio/CoreAudioTypes.h>

@protocol RFYAudioProducer <NSObject>
- (int)process:(AudioBufferList *)buffer length:(UInt32)frames;
@end
