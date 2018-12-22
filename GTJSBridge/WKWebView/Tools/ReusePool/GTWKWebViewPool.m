//
//  GTWKWebViewPool.m
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import "GTWKWebViewPool.h"
#import "GTWKWebView.h"

@interface GTWKWebViewPool()
@property(nonatomic, strong, readwrite) dispatch_semaphore_t lock;
@property(nonatomic, strong, readwrite) NSMutableSet<__kindof GTWKWebView *> *visiableWebViewSet;
@property(nonatomic, strong, readwrite) NSMutableSet<__kindof GTWKWebView *> *reusableWebViewSet;
@end

@implementation GTWKWebViewPool


+ (void)load {
    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self prepareWebView];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
}

+ (void)prepareWebView {
    [[GTWKWebViewPool sharedInstance] _prepareReuseWebView];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static GTWKWebViewPool *webViewPool = nil;
    dispatch_once(&once,^{
        webViewPool = [[GTWKWebViewPool alloc] init];
    });
    return webViewPool;
}

- (instancetype)init{
    self = [super init];
    if(self){
        _prepare = YES;
        _visiableWebViewSet = [NSSet set].mutableCopy;
        _reusableWebViewSet = [NSSet set].mutableCopy;

        _lock = dispatch_semaphore_create(1);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_clearReusableWebViews) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

#pragma mark - Public Method
- (__kindof GTWKWebView *)getReusedWebViewForHolder:(id)holder{
    if (!holder) {
#if DEBUG
        NSLog(@"GTWKWebViewPool must have a holder");
#endif
        return nil;
    }

    [self _tryCompactWeakHolders];

    GTWKWebView *webView;

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);

    if (_reusableWebViewSet.count > 0) {
        webView = (GTWKWebView *)[_reusableWebViewSet anyObject];
        [_reusableWebViewSet removeObject:webView];
        [_visiableWebViewSet addObject:webView];

        [webView webViewWillReuse];
    } else {
        webView = [[GTWKWebView alloc] initWithFrame:CGRectZero];
        [_visiableWebViewSet addObject:webView];
    }
    webView.holderObject = holder;

    dispatch_semaphore_signal(_lock);

    return webView;
}

- (void)recycleReusedWebView:(__kindof GTWKWebView *)webView{
    if (!webView) {
        return;
    }

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);

    if ([_visiableWebViewSet containsObject:webView]) {
        //将webView重置为初始状态
        [webView webViewEndReuse];

        [_visiableWebViewSet removeObject:webView];
        [_reusableWebViewSet addObject:webView];

    } else {
        if (![_reusableWebViewSet containsObject:webView]) {
#if DEBUG
            NSLog(@"GTWKWebViewPool没有在任何地方使用这个webView");
#endif
        }
    }
    dispatch_semaphore_signal(_lock);
}

- (void)cleanReusableViews{
    [self _clearReusableWebViews];
}

#pragma mark - Private Method
- (void)_tryCompactWeakHolders {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);

    NSMutableSet<GTWKWebView *> *shouldreusedWebViewSet = [NSMutableSet set];

    for (GTWKWebView *webView in _visiableWebViewSet) {
        if (!webView.holderObject) {
            [shouldreusedWebViewSet addObject:webView];
        }
    }

    for (GTWKWebView *webView in shouldreusedWebViewSet) {
        [webView webViewEndReuse];

        [_visiableWebViewSet removeObject:webView];
        [_reusableWebViewSet addObject:webView];
    }

    dispatch_semaphore_signal(_lock);
}

- (void)_clearReusableWebViews {
    [self _tryCompactWeakHolders];

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_reusableWebViewSet removeAllObjects];
    dispatch_semaphore_signal(_lock);

    [GTWKWebView clearAllWebCacheCompletion:nil];
}

- (void)_prepareReuseWebView {
    if (!_prepare) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        GTWKWebView *webView = [[GTWKWebView alloc] initWithFrame:CGRectZero];
        [self->_reusableWebViewSet addObject:webView];
    });
}

#pragma mark - Other
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
