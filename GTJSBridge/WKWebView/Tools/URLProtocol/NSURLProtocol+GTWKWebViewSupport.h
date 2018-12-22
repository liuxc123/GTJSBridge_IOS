//
//  NSURLProtocol+GTWKWebViewSupport.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (GTWKWebViewSupport)

+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;

@end
