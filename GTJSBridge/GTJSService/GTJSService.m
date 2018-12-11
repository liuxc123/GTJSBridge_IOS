//
//  GTJSService.m
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import "GTJSService.h"
#import "GTJSPluginManager.h"
#import "GTJSCommandQueue.h"
#import "GTJSCommandDelegate.h"

NSString *const GTJSBridgeConnectNotification = @"GTJSBridgeConnectNotification";
NSString *const GTJSBridgeCloseNotification = @"GTJSBridgeCloseNotification";
NSString *const GTJSBridgeWebFinishLoadNotification = @"GTJSBridgeWebFinishLoadNotification";

NSString *const JsBridgeServiceTag = @"GTJSbridgeservice";

//在JS端定义字段回收代码
#define JsBridgeScheme @"GTJSbridge"


@interface GTJSService () {
    NSString *_userAgent;  //用于记录绑定webview进来的UserAgent
}

@property (weak, nonatomic) id<WKWebViewDelegate> originDelegate;  //记录绑定webView的原始delegate
@property (strong, nonatomic) GTJSPluginManager *pluginManager;  //本地插件管理器

@end


@implementation GTJSService

- (id)init
{
    NSAssert(NO, @"Bridge Service must init with plugin config file");
    return nil;
}


- (id)initBridgeServiceWithConfig:(NSString *)configFile;
{
    self = [super init];
    if (self) {
        _webView = nil;
        _viewController = nil;
        _originDelegate = nil;
        _pluginManager = [[GTJSPluginManager alloc] initWithConfigFile:configFile];
        _commandQueue = [[GTJSCommandQueue alloc] initWithService:self];
        _commandDelegate = [[GTJSCommandDelegateImpl alloc] initWithService:self];
        
        //设置当前webview的UserAgent,方便webview注入版本信息
        _userAgent = [[[UIWebView alloc] init]
                      stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        NSString *appVersion =
        [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        NSString *customUserAgent = [_userAgent stringByAppendingFormat:@" _MAPP_/%@", appVersion];
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : customUserAgent}];
    }
    return self;
}


- (void)dealloc
{
    [self close];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"UserAgent" : _userAgent }];
    [_commandQueue dispose];
}


- (void)connect:(WKWebView *)webView Controller:(id)controller
{
    if (webView == self.webView) return;
    if (self.webView != nil) {
        [self close];
    }
    
    self.viewController = controller;
    self.webView = webView;
    self.originDelegate = webView.delegate;
    self.webView.delegate = self;
    
    //注册webViewDelegate的KVO
    [self registerKVO];
    
    // bridge连接成功，通知所有插件获取bridgeService
    [[NSNotificationCenter defaultCenter] postNotificationName:GTJSBridgeConnectNotification
                                                        object:self
                                                      userInfo:@{JsBridgeServiceTag : self}];
}


- (void)close
{
    [self unregisterKVP];
    if (self.webView == nil) return;
    
    // bridgeService关闭，通知所有插件断开bridge
    [[NSNotificationCenter defaultCenter] postNotificationName:GTJSBridgeCloseNotification
                                                        object:self];
    
    self.webView.delegate = self.originDelegate;
    self.originDelegate = nil;
    self.webView = nil;
    self.viewController = nil;
}


- (void)readyWithEvent:(NSString *)eventName
{
    //加载结束核心JS结束之后通知前端
    NSString *jsReady = [NSString stringWithFormat:@"mapp.execPatchEvent('%@');", eventName];
    [self jsEvalIntrnal:jsReady];
}


#pragma mark - 执行JS函数
- (void)jsEval:(NSString *)js
{
    [self performSelectorOnMainThread:@selector(jsEvalIntrnal:) withObject:js waitUntilDone:NO];
}


/**
 * 最后执行主函数
 */
- (NSString *)jsEvalIntrnal:(NSString *)js
{
    if (self.webView) {
        return [self.webView stringByEvaluatingJavaScriptFromString:js];
    } else {
        return nil;
    }
}

#pragma mark - KVO
- (void)registerKVO
{
    if (_webView) {
        [_webView addObserver:self
                   forKeyPath:@"delegate"
                      options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                      context:nil];
    }
}


- (void)unregisterKVP
{
    if (_webView) {
        [_webView removeObserver:self forKeyPath:@"delegate"];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    id newDelegate = change[@"new"];
    if (object == self.webView && [keyPath isEqualToString:@"delegate"] && newDelegate != self) {
        self.originDelegate = newDelegate;
        self.webView.delegate = self;
    }
}


#pragma mark webViewDelegate monitor
/**
 * 由于前端有时需要在document.ready调用JSBridge，所以在页面加载之前加载核心JS即可保证
 */
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (webView != self.webView) return;
    if ([self.originDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.originDelegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView != self.webView) return;
    //加载本地的框架JScode
    NSString *js = [_pluginManager localCoreBridgeJSCode];
    [self jsEvalIntrnal:js];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTJSBridgeWebFinishLoadNotification
                                                        object:self];
    
    if ([self.originDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.originDelegate webViewDidFinishLoad:webView];
    }
}

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView != self.webView) return YES;
    BOOL res = NO;
    NSURL *url = [request URL];
    if ([[url scheme] isEqualToString:JsBridgeScheme]) {
        [self handleURLFromWebview:[url absoluteString]];
        return NO;
    }
    
    if ([self.originDelegate
         respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        res |= [self.originDelegate webView:webView
                 shouldStartLoadWithRequest:request
                             navigationType:navigationType];
    } else {
        res = YES;
    }
    
    return res;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (webView != self.webView) return;
    
    if ([self.originDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.originDelegate webView:webView didFailLoadWithError:error];
    }
}


/*
 *@func 处理从webview发过来的的url调用请求
 */
- (void)handleURLFromWebview:(NSString *)urlstring
{
    if ([urlstring hasPrefix:JsBridgeScheme] && self.webView != nil) {
        [_commandQueue excuteCommandsFromUrl:urlstring];
    }
}


- (id)getPluginInstance:(NSString *)pluginName
{
    return [_pluginManager getPluginInstanceByPluginName:pluginName];
}


- (NSString *)realForShowMethod:(NSString *)showMethod
{
    return [_pluginManager realForShowMethod:showMethod];
}

@end
