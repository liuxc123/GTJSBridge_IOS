//
//  GTBaseWebViewController.m
//  Aspects
//
//  Created by liuxc on 2018/12/21.
//

#import "GTBaseWebViewController.h"
#import "UIProgressView+WKWebView.h"
#import <StoreKit/StoreKit.h>
#import "GTNavigationController.h"

@interface _GTWebContainerView: UIView { dispatch_block_t _hitBlock; } @end
@interface _GTWebContainerView (HitTests)
@property(copy, nonatomic) dispatch_block_t hitBlock;
@end
@implementation _GTWebContainerView
- (dispatch_block_t)hitBlock { return _hitBlock; }
- (void)setHitBlock:(dispatch_block_t)hitBlock { _hitBlock = [hitBlock copy]; }
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return [super hitTest:point withEvent:event];
}
@end

@interface GTBaseWebViewController () <SKStoreProductViewControllerDelegate>

@end

@implementation GTBaseWebViewController

#pragma mark - Life cycle

- (instancetype)init
{
    if (self = [super init]) {
        _showsToolBar = YES;
        _showProgressView = YES;
        _showsBackgroundLabel = YES;
        _showsNavigationCloseBarButtonItem = YES;
        _showsNavigationBackBarButtonItemTitle = NO;
        _reviewsAppInAppStore = NO;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL*)pageURL
{
    if(self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:pageURL.absoluteString];
        _URL = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)urlString
{
    if (self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:urlString];
        _URL = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [self init]) {
        _request = request;
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL
{
    if (self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:baseURL.absoluteString];
        _HTMLString = HTMLString;
        _baseURL = [NSURL URLWithString:urlStr];
    }
    return self;
}


- (void)loadView {
    [super loadView];

    if (@available(iOS 8.0, *)) {
        _GTWebContainerView *container = [_GTWebContainerView new];
        [container setHitBlock:^() {
            // if (!self.webView.isLoading) [self.webView reloadFromOrigin];
        }];
        [container setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:container];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(container)]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(container)]];
        [container setTag:kContainerViewTag];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSubviews];

    if (_request) {
        [self loadURLRequest:_request];
    } else if (self.URL) {
        [self loadURL:self.URL];
    } else if (_baseURL && _HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    }

    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.progressView.progressTintColor = self.navigationController.navigationBar.tintColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (_navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    if (self.navigationController) {
        if ([self.navigationController isKindOfClass:[GTUINavigationController class]]) {
            GTUIAppBarViewController *appBarController = [(GTUINavigationController *)self.navigationController naviBarViewControllerForViewController:self];
            [self updateFrameOfProgressView];
            [appBarController.navigationBar addSubview:self.progressView];
            [appBarController.navigationBar bringSubviewToFront:self.progressView];

            //设置GTUINavigationBar样式
            appBarController.navigationBar.leadingBarItemsTintColor = [UINavigationBar appearance].tintColor;
            appBarController.navigationBar.trailingBarItemsTintColor = [UINavigationBar appearance].tintColor;
        } else {
            [self updateFrameOfProgressView];
            [self.navigationController.navigationBar addSubview:self.progressView];
        }
    }

    if (_navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }

    if (_navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }

    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonClicked:)];
        [doneButton setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
        _navigationDoneItem = doneButton;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //----- SETUP DEVICE ORIENTATION CHANGE NOTIFICATION -----
    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [device beginGeneratingDeviceOrientationNotifications]; //Tell it to start monitoring the accelerometer for orientation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:device];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    if (self.navigationController) {
        [_progressView removeFromSuperview];
    }

    if (_navigationType == GTWebViewControllerNavigationTypeBarItem) {
        if ([self.navigationController isKindOfClass:[GTUINavigationController class]]) {
            self.gtui_interactivePopDisabled = YES;
            self.gtui_interactivePopMaxAllowedInitialDistanceToLeftEdge = 20;
        } else {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    }

    [self.navigationItem setLeftBarButtonItems:nil animated:NO];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && _showsToolBar && _navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }

    UIDevice *device = [UIDevice currentDevice]; //Get the device object
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:device];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if ([super respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    if (self.navigationType == GTWebViewControllerNavigationTypeBarItem) {
        [self updateNavigationItems];
    }
}

#pragma mark - Bundle

- (NSBundle *)resourceBundle{
    if (_resourceBundle) return _resourceBundle;
    NSBundle *bundle = [NSBundle bundleForClass:GTBaseWebViewController.class];

    NSString *resourcePath = [bundle pathForResource:@"GTWebViewController" ofType:@"bundle"] ;

    if (resourcePath){
        NSBundle *bundle2 = [NSBundle bundleWithPath:resourcePath];
        if (bundle2){
            bundle = bundle2;
        }
    }

    _resourceBundle = bundle;

    return _resourceBundle;
}

#pragma mark - Getters

- (UILabel *)backgroundLabel
{
    if (_backgroundLabel) return _backgroundLabel;
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    _backgroundLabel.hidden = !self.showsBackgroundLabel;
    return _backgroundLabel;
}

- (UIProgressView *)progressView {
    if (_progressView) return _progressView;
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[UIProgressView alloc] initWithFrame:barFrame];
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.hiddenWhenWebDidLoad = YES;
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    // Set the web view controller to progress view.
    __weak typeof(self) wself = self;
    _progressView.webViewController = wself;
    return _progressView;
}


- (UIBarButtonItem *)backBarButtonItem {
    if (_backBarButtonItem) return _backBarButtonItem;

    _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:
                          [UIImage imageNamed:@"GTWebViewControllerBack" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(goBackClicked:)];
    _backBarButtonItem.width = 18.0f;
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (_forwardBarButtonItem) return _forwardBarButtonItem;

    _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:
                             [UIImage imageNamed:@"GTWebViewControllerNext" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(goForwardClicked:)];
    _forwardBarButtonItem.width = 18.0f;
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (_refreshBarButtonItem) return _refreshBarButtonItem;
    _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (_stopBarButtonItem) return _stopBarButtonItem;
    _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (_actionBarButtonItem) return _actionBarButtonItem;
    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    return _actionBarButtonItem;
}

- (UIBarButtonItem *)navigationBackBarButtonItem {
    if (_navigationBackBarButtonItem) return _navigationBackBarButtonItem;

    UIImage* backItemImage = [[[UINavigationBar appearance] backIndicatorImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]?:[[UIImage imageNamed:@"backItemImage" inBundle:self.resourceBundle compatibleWithTraitCollection:nil]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    if (self.showsNavigationBackBarButtonItemTitle) {
        NSString *backBarButtonItemTitleString = self.showsNavigationBackBarButtonItemTitle ? GTWebViewControllerLocalizedString(@"back", @"back") : @"";
        _navigationBackBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:backBarButtonItemTitleString style:UIBarButtonItemStyleDone target:self action:@selector(navigationItemHandleBack:)];
        [_navigationBackBarButtonItem setImage:backItemImage];
        [_navigationBackBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];
    } else {
        _navigationBackBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backItemImage style:UIBarButtonItemStyleDone target:self action:@selector(navigationItemHandleBack:)];
    }

    _navigationBackBarButtonItem.accessibilityIdentifier = @"back_bar_button";
    _navigationBackBarButtonItem.accessibilityLabel = @"back";
    return _navigationBackBarButtonItem;
}

- (UIBarButtonItem *)navigationCloseBarButtonItem {
    if (_navigationCloseBarButtonItem) return _navigationCloseBarButtonItem;

    if (self.navigationItem.rightBarButtonItem == _navigationDoneItem && self.navigationItem.rightBarButtonItem != nil) {

        if (self.navigationCloseBarButtonItemImage == nil) {
            _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:GTWebViewControllerLocalizedString(@"close", @"close") style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonClicked:)];
        } else {
            _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[self.navigationCloseBarButtonItemImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonClicked:)];
        }

    } else {
        if (self.navigationCloseBarButtonItemImage == nil) {
            _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:GTWebViewControllerLocalizedString(@"close", @"close") style:UIBarButtonItemStyleDone target:self action:@selector(navigationIemHandleClose:)];
        } else {
            _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[self.navigationCloseBarButtonItemImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] style:UIBarButtonItemStyleDone target:self action:@selector(navigationIemHandleClose:)];
        }
    }

    [_navigationCloseBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];
    return _navigationCloseBarButtonItem;
}

- (UIBarButtonItem *)navigationMoreBarButtonItem {
    if (_navigationMoreBarButtonItem) return _navigationMoreBarButtonItem;
    if (self.navigationItem.rightBarButtonItem == _navigationDoneItem && self.navigationItem.rightBarButtonItem != nil) {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:GTWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(doneButtonClicked:)];
    } else {
        _navigationCloseBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:GTWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(navigationIemHandleClose:)];
    }
    return _navigationCloseBarButtonItem;
}

#pragma mark - Setter

- (void)setShowsToolBar:(BOOL)showsToolBar {
    _showsToolBar = showsToolBar;
    if (_navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    }
}
- (void)setShowsBackgroundLabel:(BOOL)showsBackgroundLabel{
    _backgroundLabel.hidden = !showsBackgroundLabel;
    _showsBackgroundLabel = showsBackgroundLabel;
}
- (void)setShowsNavigationCloseBarButtonItem:(BOOL)showsNavigationCloseBarButtonItem{
    _navigationCloseBarButtonItem = nil;
    _showsNavigationCloseBarButtonItem = showsNavigationCloseBarButtonItem;
    [self updateNavigationItems];
}
- (void)setShowsNavigationBackBarButtonItemTitle:(BOOL)showsNavigationBackBarButtonItemTitle{
    _navigationBackBarButtonItem = nil;
    _showsNavigationBackBarButtonItemTitle = showsNavigationBackBarButtonItemTitle;
    [self updateNavigationItems];
}

- (void)setNavigationCloseItem:(UIBarButtonItem *)navigationCloseItem {
    _navigationCloseBarButtonItem = navigationCloseItem;
    [self updateNavigationItems];
}


- (void)updateFrameOfProgressView
{
    if ([self.navigationController isKindOfClass:[GTUINavigationController class]]) {
        CGFloat progressBarHeight = 2.0f;
        GTUIAppBarViewController *appBarController = [(GTUINavigationController *)self.navigationController naviBarViewControllerForViewController:self];
        CGRect navigationBarBounds = appBarController.navigationBar.bounds;
        CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height, navigationBarBounds.size.width, progressBarHeight);
        _progressView.frame = barFrame;
        return;
    }
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    self.progressView.frame = barFrame;
}

#pragma mark - Actions

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)orientationChanged:(NSNotification *)note
{
    if (self.navigationType == GTWebViewControllerNavigationTypeToolItem) {
        [self updateToolbarItems];
    } else {
        [self updateNavigationItems];
    }
}

#pragma mark - SKStoreProductViewControllerDelegate.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - for subclass inherit

- (void)setupSubviews {}

- (void)updateToolbarItems {}

- (void)updateNavigationItems {}

- (void)loadURL:(NSURL*)URL {}

- (void)loadURLRequest:(NSURLRequest *)request {}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {}

- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion {}

- (void)actionButtonClicked:(id)sender {}

- (void)goBackClicked:(UIBarButtonItem *)sender {}

- (void)goForwardClicked:(UIBarButtonItem *)sender {}

- (void)reloadClicked:(UIBarButtonItem *)sender {}

- (void)stopClicked:(UIBarButtonItem *)sender {}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {}

#pragma mark - helper
+ (NSString *)encodeWithURL:(NSString *)URLString
{
    return [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
