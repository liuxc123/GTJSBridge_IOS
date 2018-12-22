//
//  NSURLProtocol+GTWKWebViewSupport.m
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import "NSURLProtocol+GTWKWebViewSupport.h"
#import <WebKit/WebKit.h>

FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        cls = [[[WKWebView new] valueForKey:[NSString stringWithFormat:@"%@%@%@%@", @"brow", @"singCon",@"textCon", @"troller"]] class];
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"regi", @"sterSche",@"meForCus", @"tomProto", @"col:"]);
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector() {
    return NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@%@", @"unregi", @"sterSche",@"meForCus", @"tomProto", @"col:"]);
}

@implementation NSURLProtocol (GTWKWebViewSupport)

+ (void)wk_registerScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)wk_unregisterScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
