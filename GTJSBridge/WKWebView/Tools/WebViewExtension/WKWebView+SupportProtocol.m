//
//  WKWebView+SupportProtocol.m
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import "WKWebView+SupportProtocol.h"
#import "NSURLProtocol+GTWKWebViewSupport.h"

@implementation WKWebView (SupportProtocol)

+ (void)registerSupportProtocolWithHTTP:(BOOL)supportHTTP customSchemeArray:(NSArray<NSString *> *)customSchemeArray {

    if (!supportHTTP && [customSchemeArray count] <= 0) {
        return;
    }

    if (supportHTTP) {
        [NSURLProtocol wk_registerScheme:@"http"];
        [NSURLProtocol wk_registerScheme:@"https"];
    }

    for (NSString *scheme in customSchemeArray) {
        [NSURLProtocol wk_registerScheme:scheme];
    }
}

+ (void)unregisterSupportProtocolWithHTTP:(BOOL)supportHTTP customSchemeArray:(NSArray<NSString *> *)customSchemeArray {

    if (!supportHTTP && [customSchemeArray count] <= 0) {
        return;
    }

    if (supportHTTP) {
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
    }

    for (NSString *scheme in customSchemeArray) {
        [NSURLProtocol wk_unregisterScheme:scheme];
    }
}

@end
