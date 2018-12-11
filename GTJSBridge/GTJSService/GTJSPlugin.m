//
//  GTJSPlugin.m
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import "GTJSPlugin.h"
#import "GTJSService.h"

@implementation GTJSPlugin

// Do not override these methods. Use pluginInitialize instead.
- (id)init
{
    self = [super init];
    if (self) {
        _bridgeService = nil;
        _isReady = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onConnect:)
                                                     name:GTJSBridgeConnectNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onClose:)
                                                     name:GTJSBridgeCloseNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWebViewFinishLoad:)
                                                     name:GTJSBridgeWebFinishLoadNotification
                                                   object:nil];
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)pluginInitialize
{
}


- (void)stopPlugin
{
    self.bridgeService = nil;
    self.isReady = NO;
}


- (void)onConnect:(NSNotification *)notification
{
    if (!self.bridgeService)
        self.bridgeService = [notification.userInfo objectForKey:JsBridgeServiceTag];
}


- (UIViewController *)viewController
{
    if (self.bridgeService) {
        return (UIViewController *)self.bridgeService.viewController;
    } else {
        NSAssert(NO, @"the bridge Service is not connected");
        return nil;
    }
}

- (WKWebView *)webView
{
    if (self.bridgeService) {
        return (WKWebView *)self.bridgeService.webView;
    } else {
        NSAssert(NO, @"the bridge Service is not connected");
        return nil;
    }
}

- (id<GTJSCommandDelegate>)commandDelegate
{
    if (self.bridgeService) {
        return self.bridgeService.commandDelegate;
    } else {
        NSAssert(NO, @"the bridge Service is not connected");
        return nil;
    }
}


- (void)onClose:(NSNotification *)notification
{
    if (self.bridgeService && self.bridgeService == notification.object) {
        self.bridgeService = nil;
        self.isReady = NO;
        [self stopPlugin];
    }
}

- (void)onWebViewFinishLoad:(NSNotification *)notification
{
    if (self.bridgeService && self.bridgeService == notification.object) {
        self.isReady = YES;
    }
}


- (NSString *)writeJavascript:(NSString *)javascript
{
    return [self.bridgeService jsEvalIntrnal:javascript];
}

@end
