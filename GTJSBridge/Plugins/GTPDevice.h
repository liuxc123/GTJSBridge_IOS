//
//  GTPDevice.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GTJSPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTPDevice : GTJSPlugin

/**
 *@func 获取设备信息
 */
- (void)getDeviceInfo:(GTJSInvokedUrlCommand *)command;

/**
 *@func 获取客户端信息
 */
- (void)getClientInfo:(GTJSInvokedUrlCommand *)command;

/**
 *@func 获取当前网络状况
 */
- (void)getNetworkInfo:(GTJSInvokedUrlCommand *)command;

/**
 *@func 获取webview类型
 */
- (void)getWebViewType:(GTJSInvokedUrlCommand *)command;


/**
 *@func 连接wifi
 */
- (void)connectToWiFi:(GTJSInvokedUrlCommand *)command;


/**
 *@func 设置屏幕是否常亮
 */
- (void)setScreenStatus:(GTJSInvokedUrlCommand *)command;

@end

NS_ASSUME_NONNULL_END
