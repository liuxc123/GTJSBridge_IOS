//
//  GTJSPlugin.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "GTJSInvokedUrlCommand.h"
#import "GTJSPluginResult.h"
#import "GTJSQueue.h"
#import "GTJSCommandDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class GTJSPlugin
 * 所有本地插件继承的基类
 */
@class GTJSService;
@interface GTJSPlugin : NSObject {
}
//在bridgeService中提供对webview和controller的访问
@property (weak, nonatomic) GTJSService *bridgeService;
@property (assign, nonatomic) UIViewController *viewController;
@property (assign, nonatomic) WKWebView *webView;
@property (assign, nonatomic) id<GTJSCommandDelegate> commandDelegate;
@property (assign, nonatomic) BOOL isReady;

/**
 * 插件不自己初始化，如果需要初始化插件内容，调用此方法
 */
- (void)pluginInitialize;

/**
 * 停止插件使用
 */
- (void)stopPlugin;

/**
 * 监听Bridge服务开启
 */
- (void)onConnect:(NSNotification *)notification;

/**
 * 监听Bridge服务关闭
 */
- (void)onClose:(NSNotification *)notification;

/**
 * 监听Bridge绑定的webview加载完毕事件
 */
- (void)onWebViewFinishLoad:(NSNotification *)notification;


/**
 *直接在插件中向webView发送JS执行代码
 */
- (NSString *)writeJavascript:(NSString *)javascript;

@end


NS_ASSUME_NONNULL_END
