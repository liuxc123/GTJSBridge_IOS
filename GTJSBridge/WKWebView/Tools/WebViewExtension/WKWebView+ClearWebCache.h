//
//  WKWebView+ClearWebCache.h
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import <WebKit/WebKit.h>

@interface WKWebView (ClearWebCache)

+ (void)clearAllWebCacheCompletion:(dispatch_block_t)completion;

- (void)clearBrowseHistory;

@end
