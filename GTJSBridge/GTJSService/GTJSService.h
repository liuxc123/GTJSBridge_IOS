//
//  GTJSService.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const GTJSBridgeConnectNotification;  // Bridge和webview绑定消息
extern NSString *const GTJSBridgeCloseNotification;  // Bridge和webView断开消息
extern NSString *const GTJSBridgeWebFinishLoadNotification;  // Bridge绑定WebView加载完毕

extern NSString *const JsBridgeServiceTag;  //获取Notification的service Tag

/**
 * 用于连接bridgeService的Controller定义是否需要调试
 * 如果是调试模式，客服端输出关于Native的打印信息
 */
@protocol GTJSWebViewBridgeProtocol <NSObject>

@required
- (BOOL)isDebugMode;

@optional
- (NSString *)debugChannel;

@end



@protocol GTJSCommandDelegate;
@class GTJSCommandQueue;

/**
 * @class GTJSService
 * JSBridge服务，提供JS和本地Native代码的连接服务
 */
@interface GTJSService : NSObject <UIWebViewDelegate> {
}

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) id viewController;
@property (nonatomic, readonly, strong) GTJSCommandQueue *commandQueue;
@property (nonatomic, readonly, strong) id<GTJSCommandDelegate> commandDelegate;


/**
 * 根据配置文件初始化BridgeService
 * 引用时需要拷贝插件配置文件（PluginConfig.json）文件作为示例编写，初始化时指定文件名
 * 在插件配置文件中指定核心JS的下载地址，本地文件名也必须和这个名保持一致
 */
- (id)initBridgeServiceWithConfig:(NSString *)configFile;


/**
 * 打开将BridgeService和webview以及webview所在Controller绑定
 */
- (void)connect:(WKWebView *)webView Controller:(id)controller;


/**
 * 关闭bridge服务连接
 */
- (void)close;


/**
 * 通知前端JSBridgeService已经准备就绪
 */
- (void)readyWithEvent:(NSString *)eventName;


/**
 * 1.根据pluginName 获取plugin的实例
 * 2.根据pluginShowMethod获取对应的SEL
 */
- (id)getPluginInstance:(NSString *)pluginName;
- (NSString *)realForShowMethod:(NSString *)showMethod;


/**
 * 调用bridge绑定的webview执行JS代码
 */
- (void)jsEval:(NSString *)js;
- (NSString *)jsEvalIntrnal:(NSString *)js;

@end


NS_ASSUME_NONNULL_END
