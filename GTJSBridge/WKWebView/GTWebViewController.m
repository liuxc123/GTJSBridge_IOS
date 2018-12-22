//
//  GTWebViewController.m
//  Aspects
//
//  Created by liuxc on 2018/12/21.
//

#import "GTWebViewController.h"
#import "GTWebViewControllerActivity.h"
#import "UIProgressView+WKWebView.h"
#import "GTWKCustomProtocol.h"
#import "GTUIToast+GTUIKit.h"
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import "GTNavigationController.h"

@interface GTWebViewController ()<WKUIDelegate, WKNavigationDelegate, SKStoreProductViewControllerDelegate>
{
    /// 是否加载中
    BOOL _loading;

    /// webview 配置信息
    WKWebViewConfiguration *_configuration;

    /// 安全策略
    WKWebViewDidReceiveAuthenticationChallengeHandler _challengeHandler;
    GTSecurityPolicy *_securityPolicy;

    /// Should adjust the content inset of web view.
    BOOL _automaticallyAdjustsScrollViewInsets;

    // WebView是否异常终止
    BOOL  _terminate;
}

/// 容器view
@property(readonly, nonatomic) UIView *containerView;

/// wkwebview导航对象
@property(nonatomic, strong) WKNavigation *navigation;

@end

@implementation GTWebViewController

- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    _enabledWebViewUIDelegate = NO;
    _maxAllowedTitleLength = 10;
    _checkUrlCanOpen = YES;
    _useCookieStorage = NO;
    _allowsWKNavigationGesture = YES;
    _needInterceptRequest = NO;
    _terminate  = NO;

    if (@available(iOS 8.0, *)) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = NO;
        /* Using contraints to view instead of bottom layout guide.
         self.edgesForExtendedLayout = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
         */
    } else {
        _timeoutInternal = 30.0;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    }
}

- (instancetype)initWithURL:(NSURL *)url cookie:(NSDictionary *)cookie {
    NSString *cookieStr = [GTWKWebView cookieStringWithParam:cookie];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (cookieStr.length > 0) {
        [request addValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }

    return [self initWithRequest:request.copy];
}

- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithURL:URL]) {
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration {
    if (self = [self initWithRequest:request]) {
        self.request = request;
        _configuration = configuration;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //注册插件Service
    if (_bridgeService == nil) {
        _bridgeService = [[GTJSService alloc] initBridgeServiceWithConfig:@"PluginConfig.json"];
    }
    [_bridgeService connect:self.webView Controller:self];

    if (self.showProgressView) {
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    [self registerSupportProtocolWithHTTP:NO schemes:@[@"post", kWKWebViewReuseScheme] protocolClass:[GTWKCustomProtocol class]];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (@available(iOS 11.0, *)) {} else {
        id<UILayoutSupport> topLayoutGuide = self.topLayoutGuide;
        id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;

        UIEdgeInsets contentInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0.0, bottomLayoutGuide.length, 0.0);
        if (!UIEdgeInsetsEqualToEdgeInsets(contentInsets, self.webView.scrollView.contentInset)) {
            [self.webView.scrollView setContentInset:contentInsets];
        }
    }
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if ([self.navigationController.topViewController isKindOfClass:[GTWebViewController class]]) {
        GTWebViewController* webVC = (GTWebViewController*)self.navigationController.topViewController;
        if (webVC.webView.canGoBack) {
            if (webVC.webView.isLoading) {
                [webVC.webView stopLoading];
            }
            [webVC.webView goBack];
            return NO;
        }else{
            if (webVC.navigationType == GTWebViewControllerNavigationTypeBarItem && [webVC.navigationItem.leftBarButtonItems containsObject:webVC.navigationDoneItem]) {
                [webVC updateNavigationItems];
                return NO;
            }
        }
    }
    return YES;
}

- (void)dealloc {
    [_webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    if (self.showProgressView) {
        [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
    [_webView removeObserver:self forKeyPath:@"scrollView.contentOffset"];
    [_webView removeObserver:self forKeyPath:@"title"];

    if (!_terminate) {
        [[GTWKWebViewPool sharedInstance] recycleReusedWebView:_webView];
    }
#if kGT_WEB_VIEW_CONTROLLER_DEBUG_LOGGING
    NSLog(@"One of GTWebViewController's instances was destroyed.");
#endif
}

#pragma mark - Override.

- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)automaticallyAdjustsScrollViewInsets {
    // Auto adjust scroll view content insets will always be false.
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
    _automaticallyAdjustsScrollViewInsets = automaticallyAdjustsScrollViewInsets;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (_automaticallyAdjustsScrollViewInsets) {
        if (@available(iOS 11.0, *)) {
            [self.webView.scrollView setContentInset:self.view.safeAreaInsets];
        } else {

        }
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        // Add progress view to navigation bar.
        if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
            [self updateFrameOfProgressView];
            [self.navigationController.navigationBar addSubview:self.progressView];
        }

        if (self.navigationController && [self.navigationController isKindOfClass:[GTUINavigationController class]]) {
            GTUIAppBarViewController *appBarController = [(GTUINavigationController *)self.navigationController naviBarViewControllerForViewController:self];
            if (self.progressView.superview != appBarController.navigationBar) {
                [self updateFrameOfProgressView];
                [appBarController.navigationBar addSubview:self.progressView];
            }
        }

        float progress = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if (progress >= self.progressView.progress) {
            [self.progressView setProgress:progress animated:YES];
        } else {
            [self.progressView setProgress:progress animated:NO];
        }
    } else if ([keyPath isEqualToString:@"scrollView.contentOffset"]) {
        // Get the current content offset.
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        self.backgroundLabel.transform = CGAffineTransformMakeTranslation(0, -contentOffset.y);
    } else if ([keyPath isEqualToString:@"title"]) {
        // Update title of vc.
        [self _updateTitleOfWebVC];
        // And update navigation items if needed.
        if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) [self updateNavigationItems];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Getters

- (WKWebView *)webView {
    if (_webView) return _webView;
    WKWebViewConfiguration *config = _configuration;
    if (!config) {
        config = [[WKWebViewConfiguration alloc] init];
        config.preferences.minimumFontSize = 9.0;
        if ([config respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [config setAllowsInlineMediaPlayback:YES];
        }

    }

    _webView = [[GTWKWebViewPool sharedInstance] getReusedWebViewForHolder:self];
    [_webView useExternalNavigationDelegate];
    [_webView setMainNavigationDelegate:self];
    // Set auto layout enabled.
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    if (_enabledWebViewUIDelegate) _webView.UIDelegate = self;
    _webView.allowsBackForwardNavigationGestures = _allowsWKNavigationGesture;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.backgroundColor = [UIColor whiteColor];

    // Obverse the content offset of the scroll view.
    [_webView addObserver:self forKeyPath:@"scrollView.contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    return _webView;
}

- (UIView *)containerView {
    return [self.view viewWithTag:kContainerViewTag];
}

#pragma mark - Setter
- (void)setEnabledWebViewUIDelegate:(BOOL)enabledWebViewUIDelegate {
    _enabledWebViewUIDelegate = enabledWebViewUIDelegate;
    if (@available(iOS 8.0, *)) {
        if (_enabledWebViewUIDelegate) {
            _webView.UIDelegate = self;
        } else {
            _webView.UIDelegate = nil;
        }
    }
}

- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal {
    _timeoutInternal = timeoutInternal;
    NSMutableURLRequest *request = [self.request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    _navigation = [_webView loadRequest:request];
    self.request = [request copy];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    _cachePolicy = cachePolicy;
    NSMutableURLRequest *request = [self.request mutableCopy];
    request.cachePolicy = _cachePolicy;
    _navigation = [_webView loadRequest:request];
    self.request = [request copy];
}

- (void)setMaxAllowedTitleLength:(NSUInteger)maxAllowedTitleLength {
    _maxAllowedTitleLength = maxAllowedTitleLength;
    [self _updateTitleOfWebVC];
}

- (void)setAllowsWKNavigationGesture:(BOOL)allowsWKNavigationGesture {
    _allowsWKNavigationGesture = allowsWKNavigationGesture;
    _webView.allowsBackForwardNavigationGestures = allowsWKNavigationGesture;
}

#pragma mark - LoadRequest

- (void)loadURLRequest:(NSURLRequest *)request {
    NSMutableURLRequest *__request = [request mutableCopy];
    _navigation = [_webView loadRequest:__request];

    if (!_useCookieStorage) {
        if ([__request.HTTPMethod isEqualToString:POSTRequest]) {
            [_webView clearBrowseHistory];
            _navigation = [self loadPostRequest:__request];
        }else{
            [_webView clearBrowseHistory];
            _navigation = [_webView gt_loadRequest:__request.copy];
        }
    }else{
        NSString *validDomain = request.URL.host;

        if (validDomain.length <= 0) {
            [_webView clearBrowseHistory];
            [_webView gt_loadRequest:__request.copy];
        }else{
            [_webView clearBrowseHistory];
            NSString *cookie = [_webView cookieStringWithValidDomain:validDomain];
            [__request addValue:cookie forHTTPHeaderField:@"Cookie"];
            [_webView gt_loadRequest:__request.copy];
        }
    }
}

- (nullable WKNavigation *)loadPostRequest:(NSMutableURLRequest *)request {
    NSString *cookie = request.allHTTPHeaderFields[@"Cookie"];

    NSString *scheme = request.URL.scheme;

    NSData *requestData = request.HTTPBody;

    NSMutableString *urlString = [NSMutableString stringWithString:request.URL.absoluteString];

    NSRange schemeRange = [urlString rangeOfString:scheme];

    [urlString replaceCharactersInRange:schemeRange withString:@"post"];

    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    NSString *bodyStr  = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];

    [newRequest setValue:bodyStr forHTTPHeaderField:@"bodyParam"];
    [newRequest setValue:scheme forHTTPHeaderField:@"oldScheme"];
    [newRequest addValue:cookie forHTTPHeaderField:@"Cookie"];

    return [_webView gt_loadRequest:newRequest.copy];
}

#pragma mark - Public

- (void)loadURL:(NSURL *)URL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [self loadURLRequest:request];
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {
    self.baseURL = baseURL;
    self.HTMLString = HTMLString;
    _navigation = [_webView loadHTMLString:HTMLString baseURL:baseURL];
}

- (void)loadHTMLTemplate:(NSString *)htmlTemplate {
    [_webView gt_loadHTMLTemplate:htmlTemplate];
}

#pragma mark - SubclassingHooks

- (void)willGoBack{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillGoBack:)]) {
        [_delegate webViewControllerWillGoBack:self];
    }
}
- (void)willGoForward{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillGoForward:)]) {
        [_delegate webViewControllerWillGoForward:self];
    }
}
- (void)willReload{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillReload:)]) {
        [_delegate webViewControllerWillReload:self];
    }
}
- (void)willStop{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerWillStop:)]) {
        [_delegate webViewControllerWillStop:self];
    }
}

- (void)didStartLoad
{
    self.backgroundLabel.text = GTWebViewControllerLocalizedString(@"loading", @"Loading");
    self.navigationItem.title = GTWebViewControllerLocalizedString(@"loading", @"Loading");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidStartLoad:)]) {
        [_delegate webViewControllerDidStartLoad:self];
    }
    _loading = YES;
}

- (void)didStartLoadWithNavigation:(WKNavigation *)navigation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [self didStartLoad];
#pragma clang diagnostic pop
    // FIXME: Handle the navigation of WKWebView.
    // ...
}

/// Did start load.
/// @param object Any object. WKNavigation if using WebKit.
- (void)_didStartLoadWithObj:(id)object {
    // Get WKNavigation class:
    Class WKNavigationClass = NSClassFromString(@"WKNavigation");
    if (WKNavigationClass == NULL) {
        if (![object isKindOfClass:WKNavigationClass] || object == nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self didStartLoad];
#pragma clang diagnostic pop
            return;
        }
    }
    if ([object isKindOfClass:WKNavigationClass]) [self didStartLoadWithNavigation:object];
}

- (void)didFinishLoad{
#if GT_WEB_VIEW_CONTROLLER_USING_WEBKIT
    @try {
        [self hookWebContentCommitPreviewHandler];
    } @catch (NSException *exception) {
    } @finally {
    }
#endif

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }

    [self _updateTitleOfWebVC];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *host = _webView.URL.host;

    self.backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", GTWebViewControllerLocalizedString(@"web page",@""), host?:bundle, GTWebViewControllerLocalizedString(@"provided",@"")];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewControllerDidFinishLoad:)]) {
        [_delegate webViewControllerDidFinishLoad:self];
    }
    _loading = NO;
}

- (void)didFailLoadWithError:(NSError *)error{
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:kGT404NotFoundHTMLPath]];
    } else {
        [self loadURL:[NSURL fileURLWithPath:kGTNetworkErrorHTMLPath]];
    }
    // #endif
    self.backgroundLabel.text = [NSString stringWithFormat:@"%@%@",GTWebViewControllerLocalizedString(@"load failed:", nil) , error.localizedDescription];
    self.navigationItem.title = GTWebViewControllerLocalizedString(@"load failed", nil);
    if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewController:didFailLoadWithError:)]) {
        [_delegate webViewController:self didFailLoadWithError:error];
    }
    [self.progressView setProgress:0.9 animated:YES];
}









+ (void)clearAllWebCache {
    [GTWKWebView clearAllWebCacheCompletion:nil];
}

- (void)clearWebCacheCompletion:(dispatch_block_t)completion {
    [GTWKWebView clearAllWebCacheCompletion:completion];
}

- (void)registerSupportProtocolWithHTTP:(BOOL)supportHTTP
                                schemes:(NSArray<NSString *> *)schemes
                          protocolClass:(Class)protocolClass {

    [GTWKWebView gt_registerProtocolWithHTTP:supportHTTP
                           customSchemeArray:schemes
                            urlProtocolClass:protocolClass];
}

- (void)unregisterSupportProtocolWithHTTP:(BOOL)supportHTTP
                                  schemes:(NSArray<NSString *> *)schemes
                            protocolClass:(Class)protocolClass {

    [GTWKWebView gt_unregisterProtocolWithHTTP:supportHTTP
                             customSchemeArray:schemes
                              urlProtocolClass:protocolClass];
}

- (void)syncCustomUserAgentWithType:(CustomUserAgentType)type customUserAgent:(NSString *)customUserAgent {
    [_webView gt_syncCustomUserAgentWithType:type customUserAgent:customUserAgent];
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    [self willGoBack];
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
    }
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [self willGoForward];
    if ([_webView canGoForward]) {
        _navigation = [_webView goForward];
    }
}
- (void)reloadClicked:(UIBarButtonItem *)sender {
    [self willReload];
    _navigation = [_webView reload];
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    [self willStop];
    [_webView stopLoading];
}

- (void)actionButtonClicked:(UIBarButtonItem *)sender {
    NSArray *activities = @[[GTWebViewControllerActivitySafari new], [GTWebViewControllerActivityChrome new]];
    NSURL *URL = _webView.URL;

    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:activities];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *popover = activityController.popoverPresentationController;
        popover.barButtonItem = sender;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
    if ([_webView canGoBack]) {
        _navigation = [_webView goBack];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - WKWebViewUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewDidClose:(WKWebView *)webView {
}
#endif


// 提示框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // Get host name of url.
    NSString *host = webView.URL.host;
    // Init the alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:GTWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle: UIAlertControllerStyleAlert];
    // Init the cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];

    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:GTWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    // Get the host of url.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:prompt?:GTWebViewControllerLocalizedString(@"messages", nil) message:host preferredStyle:UIAlertControllerStyleAlert];
    // Add text field.
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText?:GTWebViewControllerLocalizedString(@"input", nil);
        textField.font = [UIFont systemFontOfSize:12];
    }];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:GTWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}

#pragma mark - WKNavigationDelegate

//发送请求之前决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    // Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    // !!!: Fixed url handleing of navigation request instead of main url.
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
    // For appstore and system defines. This action will jump to AppStore app or the system apps.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {
        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString] && !self.reviewsAppInAppStore) {

            //show loading
            [GTUIToast presentToastWithin:self.view.window withIcon:GTUIToastIconLoading text:nil];

            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
            productVC.delegate = self;
            NSError *error;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];

            if (!error && result) {
                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:^(BOOL result, NSError * _Nullable error) {
                    if (!result || error) {
                        [GTUIToast dismissAllToastWithView:self.view.window];
                    } else {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [GTUIToast dismissAllToastWithView:self.view.window];
                        });
                    }
                }];
                [self presentViewController:productVC animated:YES completion:NULL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            } else {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [GTUIToast dismissAllToastWithView:self.view.window];
                });
            }
        }
        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            if (@available(iOS 10.0, *)) {
                [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {

        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            if (@available(iOS 10.0, *)) {
                [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }

        decisionHandler(WKNavigationActionPolicyCancel);

        return;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about' OR SELF MATCHES[cd] 'post'"] evaluateWithObject:components.scheme]) {// For any other schema but not `https`、`http`、`file` and `post`.

        if (@available(iOS 8.0, *)) { // openURL if ios version is low then 8 , app will crash
            if (!self.checkUrlCanOpen || [[UIApplication sharedApplication] canOpenURL:components.URL]) {
                if (@available(iOS 10.0, *)) {
                    [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
                } else {
                    [[UIApplication sharedApplication] openURL:components.URL];
                }
            }
        }else{
            if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
                [[UIApplication sharedApplication] openURL:components.URL];
            }
        }

        decisionHandler(WKNavigationActionPolicyCancel);
        return;

    }


    // URL actions for 404 and Errors:
    if ([[NSPredicate predicateWithFormat:@"SELF ENDSWITH[cd] %@ OR SELF ENDSWITH[cd] %@", kGT404NotFoundURLKey, kGTNetworkErrorURLKey] evaluateWithObject:components.URL.absoluteString]) {
        // Reload the original URL.
        [self loadURL:self.URL];
    }

    // Update the items.
    if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }

    //是否需要拦截请求
    if (_needInterceptRequest) {
        [self interceptRequestWithNavigationAction:navigationAction decisionHandler:decisionHandler];
    }else{
        // Call the decision handler to allow to load web page.
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)interceptRequestWithNavigationAction:(WKNavigationAction *)navigationAction
                             decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    decisionHandler(WKNavigationActionPolicyCancel);
}

//在收到响应后，决定是否跳转(表示当客户端收到服务器的响应头，根据response相关信息，可以决定这次跳转是否可以继续进行。)
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self _didStartLoadWithObj:navigation];
}

//接收到服务器跳转请求之后调用(接收服务器重定向时)
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {

}

//加载失败时调用(加载内容时发生错误时)
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
//        [webView reloadFromOrigin];
        return;
    }
    [self didFailLoadWithError:error];
}


//当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {

}

//页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [self didFinishLoad];
}

//导航期间发生错误时调用
- (void)webView:(WKWebView *)webView didFailNavigation: (null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        // [webView reloadFromOrigin];
        return;
    }
    // id _request = [navigation valueForKeyPath:@"_request"];
    [self didFailLoadWithError:error];
}

//iOS9.0以上异常终止时调用
//WKWebView 上当总体的内存占用比较大的时候，WebContent Process 会 crash，出现白屏现象
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    _terminate = YES;
    [webView reload];
//    NSString *host = webView.URL.host;
//    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:LYWebViewControllerLocalizedString(@"messages", nil) message:LYWebViewControllerLocalizedString(@"terminate", nil) preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:NULL];
//    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        [alert dismissViewControllerAnimated:YES completion:NULL];
//    }];
//    [alert addAction:cancelAction];
//    [alert addAction:okAction];
}
#endif


#pragma mark - Helper

- (void)setupSubviews {
    // Add from label and constraints.
    id topLayoutGuide = self.topLayoutGuide;
    id bottomLayoutGuide = self.bottomLayoutGuide;
    UILabel *backgroundLabel = self.backgroundLabel;

    // Add web view.
    // Set the content inset of scroll view to the max y position of navigation bar to adjust scroll view content inset.
    // To fix issue: https://github.com/devedbox/GTWebViewController/issues/10
    /*
     UIEdgeInsets contentInset = _webView.scrollView.contentInset;
     contentInset.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
     _webView.scrollView.contentInset = contentInset;
     */

    // Add background label to view.
    // UIView *contentView = _webView.scrollView.subviews.firstObject;
    [self.containerView addSubview:self.backgroundLabel];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[backgroundLabel(<=width)]" options:0 metrics:@{@"width":@(self.view.bounds.size.width)} views:NSDictionaryOfVariableBindings(backgroundLabel)]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backgroundLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:-20]];

    [self.containerView addSubview:self.webView];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView, topLayoutGuide, bottomLayoutGuide, backgroundLabel)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[backgroundLabel]-20-[_webView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(backgroundLabel, _webView)]];

    [self.containerView bringSubviewToFront:backgroundLabel];

    self.progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 2);

    [self.view addSubview:self.progressView];
    [self.view bringSubviewToFront:self.progressView];
}

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.self.webView.canGoForward;
    self.actionBarButtonItem.enabled = !self.self.webView.isLoading;

    UIBarButtonItem *refreshStopBarButtonItem = self.self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fixedSpace.width = 35.0f;
        NSArray *items = [NSArray arrayWithObjects:fixedSpace, refreshStopBarButtonItem, fixedSpace, self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, fixedSpace, self.actionBarButtonItem, nil];

        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    } else {
        NSArray *items = [NSArray arrayWithObjects: fixedSpace, self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, self.actionBarButtonItem, fixedSpace, nil];

        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        self.toolbarItems = items;
    }
}

- (void)updateNavigationItems {

    [self.view bringSubviewToFront:self.progressView];
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];

    if ([self.navigationController isKindOfClass:[GTUINavigationController class]]) {
        GTUIAppBarViewController *appBarController = [(GTUINavigationController *)self.navigationController naviBarViewControllerForViewController:self];
        appBarController.navigationBar.backItem = self.navigationBackBarButtonItem;
    }

    if (self.webView.canGoBack) {// Web view can go back means a lot requests exist.
        if (self.navigationController.viewControllers.count == 1) {
            NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray:@[self.navigationBackBarButtonItem]];
            // If the top view controller of the navigation controller is current vc, the close item is ignored.
            if (self.showsNavigationCloseBarButtonItem && self.navigationController.topViewController != self){
                [leftBarButtonItems addObject:self.navigationCloseBarButtonItem];
            }
            self.navigationItem.leftBarButtonItems = leftBarButtonItems;
        } else {
            if (self.showsNavigationCloseBarButtonItem){
                self.navigationItem.leftBarButtonItems = @[self.navigationCloseBarButtonItem];
            }else{
                self.navigationItem.leftBarButtonItems = @[];
            }
        }
    } else {
        self.navigationItem.leftBarButtonItems = @[];
    }

    //判断手势开关
    BOOL isOpenPopGestureRecognizer = self.webView.canGoBack;
    if ([self.navigationController isKindOfClass:[GTUINavigationController class]]) {
        self.gtui_interactivePopDisabled = isOpenPopGestureRecognizer;
        self.gtui_interactivePopMaxAllowedInitialDistanceToLeftEdge = 20;
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = isOpenPopGestureRecognizer;
    }

}


- (void)_updateTitleOfWebVC {
    NSString *title = self.title;

    title = title.length>0 ? title: [_webView title];

    if (title.length > _maxAllowedTitleLength) {
        title = [[title substringToIndex:_maxAllowedTitleLength-1] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title.length>0 ? title : GTWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
}

@end

@implementation GTWebViewController (Security)
- (WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    return _challengeHandler;
}

- (GTSecurityPolicy *)securityPolicy {
    return _securityPolicy;
}

- (void)setChallengeHandler:(WKWebViewDidReceiveAuthenticationChallengeHandler)challengeHandler {
    _challengeHandler = [challengeHandler copy];
}

- (void)setSecurityPolicy:(GTSecurityPolicy *)securityPolicy {
    _securityPolicy = securityPolicy;
}
@end
