//
//  GTBaseWebViewController.h
//  Aspects
//
//  Created by liuxc on 2018/12/21.
//

#import <UIKit/UIKit.h>
#import "GTWebViewMacros.h"

//导航方式
typedef NS_ENUM(NSInteger, GTWebViewControllerNavigationType) {
    /// Navigation bar items.
    GTWebViewControllerNavigationTypeBarItem,
    /// Tool bar items.
    GTWebViewControllerNavigationTypeToolItem
};

NS_ASSUME_NONNULL_BEGIN

@interface GTBaseWebViewController : UIViewController

/// 是否展示tool bar 默认YES
@property(assign, nonatomic) BOOL showsToolBar;

/// 是否展示描述Label 默认YES
@property(assign, nonatomic) BOOL showsBackgroundLabel;

/// 是否展示进度条 默认YES
@property(nonatomic, assign) BOOL showProgressView;

/// 是否展示naviBar 关闭按钮 默认YES
@property(assign, nonatomic) BOOL showsNavigationCloseBarButtonItem;

/// 是否展示返回按钮标题  默认NO
@property(assign, nonatomic) BOOL showsNavigationBackBarButtonItemTitle;

/// 是否打开app内部app store 默认YES
@property(assign, nonatomic) BOOL reviewsAppInAppStore;

/// 导航类型
@property(assign, nonatomic) GTWebViewControllerNavigationType navigationType;

/// webview初始化的URL
@property(nonatomic, strong) NSURL *URL;
@property(nonatomic, strong) NSURL *baseURL;
@property(nonatomic, strong) NSString *HTMLString;
@property(nonatomic, strong) NSURLRequest *request;


/// NavigationBar上的关闭按钮图片 如果不为nil 显示图片  如果为nil 显示文字
@property(nonatomic, strong) UIImage *navigationCloseBarButtonItemImage;

/// NavigationBar上的更多按钮图片 如果不为nil 显示图片  如果为nil 显示文字
@property(nonatomic, strong) UIImage *navigationMoreBarButtonItemImage;

#pragma mark - Bundle

/// 资源bundle
@property(nonatomic, strong) NSBundle *resourceBundle;

#pragma mark - UI

/// url 描述
@property(nonatomic, strong) UILabel *backgroundLabel;

/// 进度条
@property(nonatomic, strong) UIProgressView *progressView;

///  tool bar上的返回按钮
@property(strong, nonatomic) UIBarButtonItem *backBarButtonItem;

/// tool bar上的前进按钮
@property(strong, nonatomic) UIBarButtonItem *forwardBarButtonItem;

/// tool bar上的刷新按钮
@property(strong, nonatomic) UIBarButtonItem *refreshBarButtonItem;

/// tool bar上的停止按钮
@property(strong, nonatomic) UIBarButtonItem *stopBarButtonItem;

/// tool bar上的方法按钮
@property(strong, nonatomic) UIBarButtonItem *actionBarButtonItem;

/// NavigationBar上的返回按钮
@property(strong, nonatomic) UIBarButtonItem *navigationBackBarButtonItem;

/// NavigationBar上的关闭按钮
@property(strong, nonatomic) UIBarButtonItem *navigationCloseBarButtonItem;

/// NavigationBar上的更多按钮
@property(strong, nonatomic) UIBarButtonItem *navigationMoreBarButtonItem;

/// modal时NavigationBar上完成按钮
@property(nonatomic, strong) UIBarButtonItem *navigationDoneItem;


- (instancetype)initWithURL:(NSURL*)URL;

- (instancetype)initWithURLString:(NSString*)urlString;

- (instancetype)initWithRequest:(NSURLRequest *)request;

- (instancetype)initWithHTMLString:(NSString*)HTMLString baseURL:(NSURL*)baseURL;

// 子类使用或者继承

- (void)loadURL:(NSURL*)URL;

- (void)loadURLRequest:(NSURLRequest *)request;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

+ (NSString *)encodeWithURL:(NSString *)URLString;

@end


@interface GTBaseWebViewController()

- (void)setupSubviews;

- (void)updateToolbarItems;

- (void)updateNavigationItems;

- (void)updateFrameOfProgressView;

- (void)actionButtonClicked:(id)sender;

- (void)goBackClicked:(UIBarButtonItem *)sender;

- (void)goForwardClicked:(UIBarButtonItem *)sender;

- (void)reloadClicked:(UIBarButtonItem *)sender;

- (void)stopClicked:(UIBarButtonItem *)sender;

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender;

@end



NS_ASSUME_NONNULL_END
