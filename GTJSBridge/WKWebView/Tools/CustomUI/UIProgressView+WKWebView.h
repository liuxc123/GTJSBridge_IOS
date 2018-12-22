//
//  UIProgressView+WKWebView.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <UIKit/UIKit.h>
#import "GTBaseWebViewController.h"
@class GTBaseWebViewController;

@interface UIProgressView (WKWebView)

@property(nonatomic, assign) BOOL hiddenWhenWebDidLoad;

@property(nonatomic, weak) GTBaseWebViewController *webViewController;

@end
