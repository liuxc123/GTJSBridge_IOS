//
//  GTJSJSON.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (GTJSBridgeJSONSerializing)
- (NSString *)cdv_JSONString;
@end

@interface NSDictionary (GTJSBridgeJSONSerializing)
- (NSString *)cdv_JSONString;
@end

@interface NSString (GTJSBridgeJSONSerializing)
- (id)cdv_JSONObject;
@end


NS_ASSUME_NONNULL_END
