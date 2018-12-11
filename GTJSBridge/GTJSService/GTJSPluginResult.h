//
//  GTJSPluginResult.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, GTJSCommandStatus) {
    GTJSCommandStatus_NO_RESULT = 0,
    GTJSCommandStatus_OK,
    GTJSCommandStatus_CLASS_NOT_FOUND_EXCEPTION,
    GTJSCommandStatus_ILLEGAL_ACCESS_EXCEPTION,
    GTJSCommandStatus_INSTANTIATION_EXCEPTION,
    GTJSCommandStatus_MALFORMED_URL_EXCEPTION,
    GTJSCommandStatus_IO_EXCEPTION,
    GTJSCommandStatus_INVALID_ACTION,
    GTJSCommandStatus_JSON_EXCEPTION,
    GTJSCommandStatus_ERROR
};


/**
 * @class GTJSPluginResult
 * 封装native执行结果
 */
@interface GTJSPluginResult : NSObject {
}
@property (nonatomic, strong, readonly) NSNumber *status;
@property (nonatomic, strong, readonly) id message;

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                       messageAsString:(NSString *)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                        messageAsArray:(NSArray *)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                          messageAsInt:(int)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                       messageAsDouble:(double)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                         messageAsBool:(BOOL)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                   messageAsDictionary:(NSDictionary *)theMessage;
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                  messageToErrorObject:(int)errorCode;


/**
 * 直接封装Native处理结果
 */
- (NSString *)argumentsAsJSON;


/**
 * 将处理状态，和结果一起通过JSON形式封装；
 */
- (NSString *)toJSONString;


/**
 * 将处理结果封装成一个JS执行字符串
 */
- (NSString *)toJsCallbackString:(NSString *)callbackId;

@end


NS_ASSUME_NONNULL_END
