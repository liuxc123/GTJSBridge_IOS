//
//  WKWebView+SupportProtocol.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <WebKit/WebKit.h>

@interface WKWebView (SupportProtocol)

/**
 注册支持拦截的scheme

 @param supportHTTP 是否支持拦截HTTP(s)
 @param customSchemeArray 其他scheme
 */
+ (void)registerSupportProtocolWithHTTP:(BOOL)supportHTTP customSchemeArray:(NSArray<NSString *> *)customSchemeArray;

/**
 注销之前注册拦截的scheme

 @param supportHTTP 是否注销拦截HTTP(s)
 @param customSchemeArray 其他scheme
 */
+ (void)unregisterSupportProtocolWithHTTP:(BOOL)supportHTTP customSchemeArray:(NSArray<NSString *> *)customSchemeArray;

@end
