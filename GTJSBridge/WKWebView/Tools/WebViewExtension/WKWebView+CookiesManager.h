//
//  WKWebView+CookiesManager.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <WebKit/WebKit.h>

@interface WKWebView (CookiesManager)

+ (NSString *)cookieStringWithParam:(NSDictionary *)params;

- (NSString *)cookieStringWithValidDomain:(NSString *)validDomain;

- (NSString *)jsCookieStringWithValidDomain:(NSString *)validDomain;

@end
