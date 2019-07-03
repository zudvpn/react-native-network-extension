
// #if __has_include("RCTBridgeModule.h")
// #import "RCTBridgeModule.h"
// #else
// #import <React/RCTBridgeModule.h>
// #endif
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>


@interface RNNetworkExtension : RCTEventEmitter <RCTBridgeModule>

@end
  