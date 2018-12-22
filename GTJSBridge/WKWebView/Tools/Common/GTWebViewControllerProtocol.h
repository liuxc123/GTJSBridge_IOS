//
//  GTWebViewControllerProtocol.h
//  Aspects
//
//  Created by liuxc on 2018/12/21.
//

#import <Foundation/Foundation.h>
#import "GTWebViewController.h"

@class GTWebViewController;

#pragma mark - GTWebViewControllerDelegate

@protocol GTWebViewControllerDelegate <NSObject>
@optional
/// Called when web view will go back.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillGoBack:(GTWebViewController *)webViewController;
/// Called when web view will go forward.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillGoForward:(GTWebViewController *)webViewController;
/// Called when web view will reload.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillReload:(GTWebViewController *)webViewController;
/// Called when web view will stop load.
///
/// @param webViewController a web view controller.
- (void)webViewControllerWillStop:(GTWebViewController *)webViewController;
/// Called when web view did start loading.
///
/// @param webViewController a web view controller.
- (void)webViewControllerDidStartLoad:(GTWebViewController *)webViewController;
/// Called when web view did finish loading.
///
/// @param webViewController a web view controller.
- (void)webViewControllerDidFinishLoad:(GTWebViewController *)webViewController;
/// Called when web viw did fail loading.
///
/// @param webViewController a web view controller.
///
/// @param error a failed loading error.
- (void)webViewController:(GTWebViewController *)webViewController didFailLoadWithError:(NSError *)error;

@end

