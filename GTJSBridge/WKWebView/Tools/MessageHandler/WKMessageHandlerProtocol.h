//
//  WKMessageHandlerProtocol.h
//  Aspects
//
//  Created by liuxc on 2018/12/22.
//

#import <Foundation/Foundation.h>

@protocol WKMessageHandlerProtocol <NSObject>

///JS传给Native的参数
@property (nonatomic, strong) NSDictionary *params;

/**
 Native业务处理成功的回调,result:回调给JS的数据
 */
@property (nonatomic, copy) void(^successCallback)(NSDictionary *result);

/**
 Native业务处理失败的回调,result:回调给JS的数据
 */
@property (nonatomic, copy) void(^failCallback)(NSDictionary *result);

/**
 Native业务处理的回调,result:回调给JS的数据
 */
@property (nonatomic, copy) void(^progressCallback)(NSDictionary *result);

@end
