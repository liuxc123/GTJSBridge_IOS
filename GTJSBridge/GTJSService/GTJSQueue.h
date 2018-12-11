//
//  GTJSQueue.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (QueueAdditions)
- (id)cdv_pop;
- (id)cdv_queueHead;
- (id)cdv_dequeue;
- (void)cdv_enqueue:(id)obj;
@end

NS_ASSUME_NONNULL_END
