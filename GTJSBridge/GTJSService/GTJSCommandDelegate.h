//
//  GTJSCommandDelegate.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GTJSPluginResult;
@class GTJSService;

@protocol GTJSCommandDelegate <NSObject>
/**
 * 将执行native的结果封装并通过callBackId进行JS回调
 */
- (void)sendPluginResult:(GTJSPluginResult *)result callbackId:(NSString *)callbackId;


@end


/**
 * protocol GTJSCommandDelegate
 * 执行URLCommand的回调
 */
@interface GTJSCommandDelegateImpl : NSObject <GTJSCommandDelegate> {
}

/**
 * 初始化Command回调
 */
- (id)initWithService:(GTJSService *)jsService;

@end


NS_ASSUME_NONNULL_END
