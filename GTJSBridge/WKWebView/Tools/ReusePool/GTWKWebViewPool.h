//
//  GTWKWebViewPool.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <Foundation/Foundation.h>
@class GTWKWebView;

#define kWKWebViewReuseUrlString @"kwebkit://reuse-webView"
#define kWKWebViewReuseScheme    @"kwebkit"

@protocol GTWKWebViewReuseProtocol
- (void)webViewWillReuse;
- (void)webViewEndReuse;
@end

@interface GTWKWebViewPool : NSObject

/**
 是否需要在App启动时提前准备好一个可复用的WebView,默认为YES.
 prepare=YES时,可显著优化WKWebView首次启动时间.
 prepare=NO时,不会提前初始化一个可复用的WebView.
 */
@property(nonatomic, assign) BOOL prepare;

+ (instancetype)sharedInstance;

- (__kindof GTWKWebView *)getReusedWebViewForHolder:(id)holder;

- (void)recycleReusedWebView:(__kindof GTWKWebView *)webView;

- (void)cleanReusableViews;

@end
