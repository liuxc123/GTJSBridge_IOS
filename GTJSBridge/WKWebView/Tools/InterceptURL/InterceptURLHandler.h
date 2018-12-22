//
//  InterceptURLHandler.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <Foundation/Foundation.h>

#pragma mark - GTWebViewControllerInterceptURLDelegate
@protocol GTWebViewControllerInterceptURLProtocol <NSObject>

@required
- (void)interceptURL:(NSURL *)URL;

@end

@interface InterceptURLHandler : NSObject <GTWebViewControllerInterceptURLProtocol>

@end
