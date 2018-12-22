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

@property (weak, nonatomic) id<WKNavigationDelegate> originNavigationDelegate;  //记录绑定wkwebView的原始WKNavigationDelegate
@property (weak, nonatomic) id<WKUIDelegate> originUIDelegate;  //记录绑定wkwebView的原始WKUIDelegate
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
        _originUIDelegate = nil;
        _originNavigationDelegate = nil;
        _pluginManager = [[GTJSPluginManager alloc] initWithConfigFile:configFile];
        _commandQueue = [[GTJSCommandQueue alloc] initWithService:self];
        _commandDelegate = [[GTJSCommandDelegateImpl alloc] initWithService:self];
        
        //设置当前webview的UserAgent,方便webview注入版本信息
        [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString * _Nullable originUserAgent , NSError * _Nullable error) {
            self->_userAgent = originUserAgent;
            NSString *appVersion =
            [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
            NSString *customUserAgent = [self->_userAgent stringByAppendingFormat:@" _MAPP_/%@", appVersion];
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : customUserAgent}];
        }];
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
    
    self.originUIDelegate = webView.UIDelegate;
    self.originNavigationDelegate = webView.navigationDelegate;
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    
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
    
    self.webView.UIDelegate = self.originUIDelegate;
    self.webView.navigationDelegate = self.originNavigationDelegate;
    self.originUIDelegate = nil;
    self.originNavigationDelegate = nil;
    self.webView = nil;
    self.viewController = nil;
}


- (void)readyWithEvent:(NSString *)eventName
{
    //加载结束核心JS结束之后通知前端
    NSString *jsReady = [NSString stringWithFormat:@"mapp.execPatchEvent('%@');", eventName];
    [self jsEvalIntrnal:jsReady completionHandler:nil];
}


#pragma mark - 执行JS函数
- (void)jsEval:(NSString *)js
{
    [self performSelectorOnMainThread:@selector(jsEvalIntrnal:completionHandler:) withObject:js waitUntilDone:NO];
}


/**
 * 最后执行主函数
 */
- (void)jsEvalIntrnal:(NSString *)js completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler
{
    if (self.webView) {
        [self.webView evaluateJavaScript:js completionHandler:completionHandler];
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
//    id newDelegate = change[@"new"];
//    if (object == self.webView && [keyPath isEqualToString:@"delegate"] && newDelegate != self) {
//        self.originDelegate = newDelegate;
//
//        self.webView.delegate = self;
//    }
}


#pragma mark WKScriptMessage monitor

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {

}

#pragma mark WKNavigationDelegate monitor
/**
 * 由于前端有时需要在document.ready调用JSBridge，所以在页面加载之前加载核心JS即可保证
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (webView != self.webView) return;
    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.originNavigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    if (webView != self.webView) return;
    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [self.originNavigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView != self.webView) return;
    //加载本地的框架JScode
    NSString *js = [_pluginManager localCoreBridgeJSCode];
    [self jsEvalIntrnal:js completionHandler:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:GTJSBridgeWebFinishLoadNotification
                                                        object:self];
    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.originNavigationDelegate webView:webView didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (webView != self.webView) return;
    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [self.originNavigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (webView != self.webView) return;
    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.originNavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}


#pragma mark 这个代理方法表示接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != self.webView) return;

    NSURL *url = webView.URL;
    if ([[url scheme] isEqualToString:JsBridgeScheme]) {
        [self handleURLFromWebview:[url absoluteString]];
        return;
    }

    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.originNavigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }

}

#pragma mark 这个代理方法表示当客户端收到服务器的响应头，根据 response 相关信息，可以决定这次跳转是否可以继续进行。在发送请求之前，决定是否跳转，如果不添加这个，那么 wkwebview 跳转不了 AppStore 和 打电话
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if (webView != self.webView) return;

    NSURL *url = webView.URL;
    if ([[url scheme] isEqualToString:JsBridgeScheme]) {
        [self handleURLFromWebview:[url absoluteString]];
        return;
    }

    if ([self.originNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.originNavigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
}


- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {

    if (webView != self.webView) return;

    if (@available(iOS 9.0, *)) {
        if ([self.originNavigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
            [self.originNavigationDelegate webViewWebContentProcessDidTerminate:webView];
        }
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
