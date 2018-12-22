#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GTJSCommandDelegate.h"
#import "GTJSCommandQueue.h"
#import "GTJSInvokedUrlCommand.h"
#import "GTJSJSON.h"
#import "GTJSPlugin.h"
#import "GTJSPluginManager.h"
#import "GTJSPluginResult.h"
#import "GTJSQueue.h"
#import "GTJSService.h"
#import "GTPDevice.h"
#import "GTBaseWebViewController.h"
#import "GTWebViewController.h"
#import "GTWebViewControllerActivity.h"
#import "GTWebViewControllerProtocol.h"
#import "GTWebViewMacros.h"
#import "UIProgressView+WKWebView.h"
#import "WKWebView+AOP.h"
#import "InterceptURLHandler.h"
#import "WKCallNativeMethodMessageHandler.h"
#import "WKMessageHandlerProtocol.h"
#import "GTWKWebView.h"
#import "GTWKWebViewPool.h"
#import "GTSecurityPolicy.h"
#import "GTWKCustomProtocol.h"
#import "NSURLProtocol+GTWKWebViewSupport.h"
#import "WKWebView+ClearWebCache.h"
#import "WKWebView+CookiesManager.h"
#import "WKWebView+ExternalNavigationDelegates.h"
#import "WKWebView+SupportProtocol.h"
#import "WKWebView+SyncUserAgent.h"
#import "WKWebViewExtension.h"
#import "GTBaseWebViewController.h"
#import "GTWebViewController.h"
#import "GTWebViewControllerActivity.h"
#import "GTWebViewControllerProtocol.h"
#import "GTWebViewMacros.h"
#import "UIProgressView+WKWebView.h"
#import "WKWebView+AOP.h"
#import "InterceptURLHandler.h"
#import "WKCallNativeMethodMessageHandler.h"
#import "WKMessageHandlerProtocol.h"
#import "GTWKWebView.h"
#import "GTWKWebViewPool.h"
#import "GTSecurityPolicy.h"
#import "GTWKCustomProtocol.h"
#import "NSURLProtocol+GTWKWebViewSupport.h"
#import "WKWebView+ClearWebCache.h"
#import "WKWebView+CookiesManager.h"
#import "WKWebView+ExternalNavigationDelegates.h"
#import "WKWebView+SupportProtocol.h"
#import "WKWebView+SyncUserAgent.h"
#import "WKWebViewExtension.h"

FOUNDATION_EXPORT double GTJSBridgeVersionNumber;
FOUNDATION_EXPORT const unsigned char GTJSBridgeVersionString[];

