//
//  GTJSPluginManager.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import "GTJSPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @class GTJSExportDetail
 * 对插件对外开放JSAPI调用接口和插件native方法的对应
 */
@interface GTJSExportDetail : NSObject {
}
@property (strong, nonatomic) NSString *showMethod;  // JSAPI调用方法名
@property (strong, nonatomic) NSString *realMethod;  //插件method名

@end


/**
 * @class GTJSPluginInfo
 * 插件的详细配置描述
 */
@interface GTJSPluginInfo : NSObject {
}
@property (strong, nonatomic) NSString *pluginName;
@property (strong, nonatomic) NSString *pluginClass;
@property (strong, nonatomic) NSMutableDictionary *exports;
@property (strong, nonatomic) GTJSPlugin *instance;

/**
 *根据JSAPI调用方法名获取实际的selector method方法；
 */
- (GTJSExportDetail *)getDetailByShowMethod:(NSString *)showMethod;

@end


/**
 * @class GTJSPluginManager
 * 对本地实现所有Plugin的管理器
 */
@interface GTJSPluginManager : NSObject {
}
/**
 *根据配置文件初始化一个插件管理器
 */
- (id)initWithConfigFile:(NSString *)file;
- (void)resetWithConfigFile:(NSString *)path;


/**
 * 根据PluginName获取该插件的实例对象
 */
- (id)getPluginInstanceByPluginName:(NSString *)pluginName;


/**
 * 根据plugin的showMethod获取Native对应的SEL
 */
- (NSString *)realForShowMethod:(NSString *)showMethod;


/**
 * 从本地获取核心JS字符串
 */
- (NSString *)localCoreBridgeJSCode;

@end


NS_ASSUME_NONNULL_END
