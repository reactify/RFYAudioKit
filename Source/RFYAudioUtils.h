//
//  RFYAudioUtils.h
//  RFYAudioKit
//
//  Created by Ragnar Hrafnkelsson on 15/04/2018.
//  Copyright © 2018 Reactify. All rights reserved.
//

#ifndef RFYAudioUtils_h
#define RFYAudioUtils_h

#if defined __cplusplus
extern "C" {
#endif

#import <AVFoundation/AVFoundation.h>
#import <RFYAppKit/RFYUtils.h>

#define checkResult(result,operation) (_checkResult((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static RFY_INLINE BOOL _checkResult(OSStatus result, const char *operation, const char* file, int line) {
  if ( result != noErr ) {
    NSLog(@"%s:%d: %s result %d %08X %4.4s\n", file, line, operation, (int)result, (int)result, (char*)&result);
    return NO;
  }
  return YES;
}

AudioStreamBasicDescription nonInterleavedFloatStereo(void);

AudioBufferList *InitAudioBufferList(AudioStreamBasicDescription format, UInt32 frameCount);

void FreeAudioBufferList(AudioBufferList *bufferList);

void ClearAudioBufferList(AudioBufferList *bufferList, UInt32 frames);

void AudioBufferListMultiply(AudioBufferList *bufferList, UInt32 frames, float value);
  
#if defined __cplusplus
};
#endif

#endif /* RFYAudioUtils_h */
