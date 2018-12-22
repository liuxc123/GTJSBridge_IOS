//
//  GTWKWebView.m
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import "GTWKWebView.h"
#import "WKCallNativeMethodMessageHandler.h"

@implementation GTWKWebView

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self config];
    }
    return self;
}

#pragma mark - override
- (BOOL)canGoBack {
    if ([self.backForwardList.backItem.URL.absoluteString caseInsensitiveCompare:kWKWebViewReuseUrlString] == NSOrderedSame ||
        [self.URL.absoluteString isEqualToString:kWKWebViewReuseUrlString]) {
        return NO;
    }

    return [super canGoBack];
}

- (BOOL)canGoForward {
    if ([self.backForwardList.forwardItem.URL.absoluteString caseInsensitiveCompare:kWKWebViewReuseUrlString] == NSOrderedSame ||
        [self.URL.absoluteString isEqualToString:kWKWebViewReuseUrlString]) {
        return NO;
    }

    return [super canGoForward];
}

- (void)dealloc{
    //清除handler
    [self.configuration.userContentController removeScriptMessageHandlerForName:@"WKNativeMethodMessage"];

    //清除UserScript
    [self.configuration.userContentController removeAllUserScripts];

    //停止加载
    [self stopLoading];

    //清空Dispatcher
    [self unUseExternalNavigationDelegate];

    //清空相关delegate
    [super setUIDelegate:nil];
    [super setNavigationDelegate:nil];

    //持有者置为nil
    _holderObject = nil;

    NSLog(@"GTWKWebView dealloc");
}

#pragma mark - Configuration
- (void)config {
    //0.UI
    {
        self.backgroundColor = [UIColor clearColor];
        self.scrollView.backgroundColor = [UIColor clearColor];
    }

//    //1.注入脚本
//    {
//        NSString *bundlePath = [[NSBundle bundleForClass:self.class] pathForResource:@"GTWebViewController" ofType:@"bundle"];
//
//        NSString *scriptPath = [NSString stringWithFormat:@"%@/%@",bundlePath, @"JXBJSBridge.js"];
//
//        NSString *bridgeJSString = [[NSString alloc] initWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
//
//        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:bridgeJSString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
//
//        [self.configuration.userContentController addUserScript:userScript];
//    }

    //2.指定MessageHandler
    {
        [self.configuration.userContentController addScriptMessageHandler:[[WKCallNativeMethodMessageHandler alloc] init] name:@"WKNativeMethodMessage"];
    }

    //3.UserAgent
    {
        if (@available(iOS 9.0, *)) {
            if ([self.configuration respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {

                [self.configuration setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        }
    }

    //4.视频播放相关
    {
        if ([self.configuration respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [self.configuration setAllowsInlineMediaPlayback:YES];
        }

        //视频播放
        if (@available(iOS 10.0, *)) {
            if ([self.configuration respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]){
                [self.configuration setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
            }
        } else if (@available(iOS 9.0, *)) {
            if ( [self.configuration respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
                [self.configuration setRequiresUserActionForMediaPlayback:NO];
            }
        } else {
            if ( [self.configuration respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
                [self.configuration setMediaPlaybackRequiresUserAction:NO];
            }
        }
    }


}

#pragma mark - GTWKWebViewReuseProtocol

//即将被复用时
- (void)webViewWillReuse{
    [self useExternalNavigationDelegate];
}

//被回收
- (void)webViewEndReuse{
    _holderObject = nil;
    self.scrollView.delegate = nil;

    [self stopLoading];

    [self unUseExternalNavigationDelegate];

    [super setUIDelegate:nil];

    [super clearBrowseHistory];

    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kWKWebViewReuseUrlString]]];

    //删除所有的回调事件
    [self evaluateJavaScript:@"JSCallBackMethodManager.removeAllCallBacks();" completionHandler:^(id _Nullable data, NSError * _Nullable error) {

    }];
}

#pragma mark - public method
- (WKNavigation *)gt_loadRequestURLString:(NSString *)urlString {
    return [self gt_loadRequestURL:[NSURL URLWithString:urlString]];
}


- (WKNavigation *)gt_loadRequestURL:(NSURL *)url {
    return [self gt_loadRequestURL:url cookie:nil];
}

- (WKNavigation *)gt_loadRequestURL:(NSURL *)url cookie:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    __block NSMutableString *cookieStr = [NSMutableString string];
    if (params) {
        [params enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, NSString* _Nonnull value, BOOL * _Nonnull stop) {
            [cookieStr appendString:[NSString stringWithFormat:@"%@ = %@;", key, value]];
        }];
    }

    if (cookieStr.length > 1)[cookieStr deleteCharactersInRange:NSMakeRange(cookieStr.length - 1, 1)];

    [request addValue:cookieStr forHTTPHeaderField:@"Cookie"];

    return [self gt_loadRequest:request.copy];
}

- (WKNavigation *)gt_loadRequest:(NSURLRequest *)requset {
    return [super loadRequest:requset];
}

- (WKNavigation *)gt_loadHTMLTemplate:(NSString *)htmlTemplate {
    return [super loadHTMLString:htmlTemplate baseURL:nil];
}

#pragma mark - Cache
+ (void)gt_clearAllWebCache {
    [super clearAllWebCacheCompletion:nil];
}

#pragma mark - UserAgent
- (void)gt_syncCustomUserAgentWithType:(CustomUserAgentType)type customUserAgent:(NSString *)customUserAgent {
    [super syncCustomUserAgentWithType:type customUserAgent:customUserAgent];
}

#pragma mark - register intercept protocol
+ (void)gt_registerProtocolWithHTTP:(BOOL)supportHTTP
                   customSchemeArray:(NSArray<NSString *> *)customSchemeArray
                    urlProtocolClass:(Class)urlProtocolClass {

    if (!urlProtocolClass) {
        return;
    }

    [NSURLProtocol registerClass:urlProtocolClass];
    [super registerSupportProtocolWithHTTP:supportHTTP customSchemeArray:customSchemeArray];
}

+ (void)gt_unregisterProtocolWithHTTP:(BOOL)supportHTTP
                     customSchemeArray:(NSArray<NSString *> *)customSchemeArray
                      urlProtocolClass:(Class)urlProtocolClass {

    if (!urlProtocolClass) {
        return;
    }

    [NSURLProtocol unregisterClass:urlProtocolClass];
    [super unregisterSupportProtocolWithHTTP:supportHTTP customSchemeArray:customSchemeArray];
}

@end
