//
//  WKWebView+ExternalNavigationDelegates.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WKWebView (ExternalNavigationDelegates)
@property(nonatomic, weak) id<WKNavigationDelegate> mainNavigationDelegate;

- (void)useExternalNavigationDelegate;
- (void)unUseExternalNavigationDelegate;
- (void)addExternalNavigationDelegate:(id<WKNavigationDelegate>)delegate;
- (void)removeExternalNavigationDelegate:(id<WKNavigationDelegate>)delegate;
- (BOOL)containsExternalNavigationDelegate:(id<WKNavigationDelegate>)delegate;
- (void)clearExternalNavigationDelegates;
@end
