//
//  GTJSCommandQueue.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GTJSInvokedUrlCommand;
@class GTJSService;

/**
 * @class GTJSCommandQueue
 * 用来存储从HTML页面发过来的调用请求命令
 */
@interface GTJSCommandQueue : NSObject {
}

@property (nonatomic, readonly) BOOL currentlyExecuting;  //用于判断当前是否在执行调用请求

/**
 * 初始化和销毁CommandQueue
 */
- (id)initWithService:(GTJSService *)jsService;
- (void)dispose;

/**
 * 从webview截获URL并执行
 */
- (void)excuteCommandsFromUrl:(NSString *)urlStr;

@end

NS_ASSUME_NONNULL_END
