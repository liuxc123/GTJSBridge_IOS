//
//  UIProgressView+WKWebView.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <UIKit/UIKit.h>
@class GTWebViewController;

@interface UIProgressView (WKWebView)

@property(nonatomic, assign) BOOL hiddenWhenWebDidLoad;

@property(nonatomic, strong) GTWebViewController *webViewController;

@end
