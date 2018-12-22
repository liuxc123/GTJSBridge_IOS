//
//  GTWKWebView.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <WebKit/WebKit.h>
#import "WKWebViewExtension.h"
#import "GTWKWebViewPool.h"

@interface GTWKWebView : WKWebView <GTWKWebViewReuseProtocol>

@property(nonatomic, weak, readwrite) id holderObject;

#pragma mark - load request
- (nullable WKNavigation *)gt_loadRequestURLString:(NSString *)urlString;

- (nullable WKNavigation *)gt_loadRequestURL:(NSURL *)url;

- (nullable WKNavigation *)gt_loadRequestURL:(NSURL *)url cookie:(NSDictionary *)params;

- (nullable WKNavigation *)gt_loadRequest:(NSURLRequest *)requset;

- (nullable WKNavigation *)gt_loadHTMLTemplate:(NSString *)htmlTemplate;

#pragma mark - Cache
+ (void)gt_clearAllWebCache;

#pragma mark - UserAgent
- (void)gt_syncCustomUserAgentWithType:(CustomUserAgentType)type customUserAgent:(NSString *)customUserAgent;

#pragma mark - register intercept protocol
+ (void)gt_registerProtocolWithHTTP:(BOOL)supportHTTP
                   customSchemeArray:(NSArray<NSString *> *)customSchemeArray
                    urlProtocolClass:(Class)urlProtocolClass;

+ (void)gt_unregisterProtocolWithHTTP:(BOOL)supportHTTP
                     customSchemeArray:(NSArray<NSString *> *)customSchemeArray
                      urlProtocolClass:(Class)urlProtocolClass;

@end
