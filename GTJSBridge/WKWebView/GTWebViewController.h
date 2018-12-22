//
//  GTWebViewController.h
//  Aspects
//
//  Created by liuxc on 2018/12/21.
//

#import "GTBaseWebViewController.h"
#import "GTWKWebView.h"
#import "GTSecurityPolicy.h"
#import "WKWebViewExtension.h"
#import "InterceptURLHandler.h"
#import "GTWebViewControllerProtocol.h"
#import "GTJSService.h"


@interface GTWebViewController : GTBaseWebViewController

/// 拦截URL代理对象,不需要默认处理可自定义
@property(nonatomic, strong) id<GTWebViewControllerInterceptURLProtocol> interceptURLDelegate;

/// 代理对象
@property(assign, nonatomic) id<GTWebViewControllerDelegate>delegate;

/// 当前Web控件
@property(nonatomic, strong) GTWKWebView *webView;

/// 是否允许展示AlertView 默认NO.
@property(assign, nonatomic) BOOL enabledWebViewUIDelegate;

/// 标题最大长度 默认是10.
@property(assign, nonatomic) NSUInteger maxAllowedTitleLength;

/// 超时时间
@property(assign, nonatomic) NSTimeInterval timeoutInternal;

/// Web缓存模式
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;

/// 是否验证URL是否能打开 默认YES
@property(assign, nonatomic) BOOL checkUrlCanOpen API_AVAILABLE(ios(8.0));

/**
 通过使用NSHTTPCookieStorage,根据URL Domain找到之前存储的cookie,进行加载.
 示例:使用AFN请求https://XX/login接口,获取到用户token等信息,要想在H5中使用这些token信息,要保证H5的URL的domain也是XX才行.否则获取不到.
 如果想在与NativeRequestApi域名不相同的H5 URL中使用Cookie,使用initWithCookieRequest:方法,自己拼接好cookie通过NSURLRequest加到header中.
 */
@property(nonatomic, assign) BOOL useCookieStorage;

/// 是否允许使用H5的侧滑返回手势,WebView复用的情况下默认为YES.
@property(nonatomic, assign) BOOL allowsWKNavigationGesture;

/**
 是否需要拦截请求,默认NO,如果设置为YES,则会将请求cancel,然后调用interceptRequestWithNavigationAction:方法

 如果有以下场景请将该属性设置为YES
 1.重新设置cookie
 2.给url追加参数
 */
@property(nonatomic, assign) BOOL needInterceptRequest;


@property(nonatomic, weak, readwrite) GTJSService *bridgeService;

/**
 初始化方法
 */
- (instancetype)init;

- (instancetype)initWithURL:(NSURL *)url cookie:(NSDictionary *)cookie;

- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration;

- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration;



- (void)loadURL:(NSURL*)URL;

- (void)loadHTMLTemplate:(NSString *)htmlTemplate;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;


//注册拦截的scheme和class
- (void)registerSupportProtocolWithHTTP:(BOOL)supportHTTP
                                schemes:(NSArray<NSString *> *)schemes
                          protocolClass:(Class)protocolClass;

//注销拦截的scheme和class
- (void)unregisterSupportProtocolWithHTTP:(BOOL)supportHTTP
                                  schemes:(NSArray<NSString *> *)schemes
                            protocolClass:(Class)protocolClass;

//设置UserAgent
- (void)syncCustomUserAgentWithType:(CustomUserAgentType)type
                    customUserAgent:(NSString *)customUserAgent;


// clear cache
+ (void)clearAllWebCache;

// clear cache
- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

@end




/**
 使用的时候需要子类化，并且调用super的方法!切记！！！
 */
@interface GTWebViewController (SubclassingHooks)
/**
 如果needInterceptReq设置为YES,会调用该方法,为了保证流程可以正常执行,当needInterceptReq设置为YES时子类务必重写该方法

 @param navigationAction 通过该参数可以获取request和url,可以自行设置cookie或给url追加参数,然后让webView重新loadRequest
 */
- (void)interceptRequestWithNavigationAction:(WKNavigationAction *)navigationAction
                             decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

/// 即将后退
- (void)willGoBack GT_REQUIRES_SUPER;

/// 即将前进
- (void)willGoForward GT_REQUIRES_SUPER;

/// 即将前进
- (void)willReload GT_REQUIRES_SUPER;

/// 即将结束
- (void)willStop GT_REQUIRES_SUPER;

/// 开始加载
- (void)didStartLoadWithNavigation:(WKNavigation *)navigation GT_REQUIRES_SUPER NS_AVAILABLE(10_10, 8_0);

/// 已经加载完成
- (void)didFinishLoad GT_REQUIRES_SUPER;

/// 加载出错
- (void)didFailLoadWithError:(NSError *)error GT_REQUIRES_SUPER;

@end



/**
 网络安全策略
 */
typedef NSURLSessionAuthChallengeDisposition (^WKWebViewDidReceiveAuthenticationChallengeHandler)(WKWebView *webView, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential);

@interface GTWebViewController (Security)
/// Challenge handler for the credential.
@property(copy, nonatomic, nullable) WKWebViewDidReceiveAuthenticationChallengeHandler challengeHandler;
/// The security policy used by created session to evaluate server trust for secure connections.
/// `GTWebViewController` uses the `defaultPolicy` unless otherwise specified.
@property(readwrite, nonatomic, nullable) GTSecurityPolicy *securityPolicy;
@end
