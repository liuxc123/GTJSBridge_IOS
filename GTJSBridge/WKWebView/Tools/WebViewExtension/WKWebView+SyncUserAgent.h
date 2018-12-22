//
//  WKWebView+SyncUserAgent.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <WebKit/WebKit.h>

typedef NS_ENUM (NSInteger, CustomUserAgentType){
    CustomUserAgentTypeDefault,     //使用系统默认的
    CustomUserAgentTypeReplace,     //替换所有UA
    CustomUserAgentTypeAppend,      //在原UA后面追加字符串
};

@interface WKWebView (SyncUserAgent)

/**
 *  设置UserAgent
 *
 *  @param type            replace or append original UA
 *  @param customUserAgent    customUserAgent
 */
- (void)syncCustomUserAgentWithType:(CustomUserAgentType)type customUserAgent:(NSString *)customUserAgent;

@end
