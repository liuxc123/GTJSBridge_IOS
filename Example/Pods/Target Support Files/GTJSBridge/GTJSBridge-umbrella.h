#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GTJSCommandDelegate.h"
#import "GTJSCommandQueue.h"
#import "GTJSInvokedUrlCommand.h"
#import "GTJSJSON.h"
#import "GTJSPlugin.h"
#import "GTJSPluginManager.h"
#import "GTJSPluginResult.h"
#import "GTJSQueue.h"
#import "GTJSService.h"
#import "GTPDevice.h"

FOUNDATION_EXPORT double GTJSBridgeVersionNumber;
FOUNDATION_EXPORT const unsigned char GTJSBridgeVersionString[];

