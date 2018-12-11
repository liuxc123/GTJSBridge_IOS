//
//  GTJSPluginResult.m
//  GTJSBridge
//
//  Created by liuxc on 2018/12/11.
//

#import "GTJSPluginResult.h"
#import "GTJSJSON.h"


@interface GTJSPluginResult () {
}

- (GTJSPluginResult *)initWithStatus:(GTJSCommandStatus)statusOrdinal message:(id)theMessage;

@end


@implementation GTJSPluginResult
@synthesize status, message;

#pragma mark - init method
- (GTJSPluginResult *)init
{
    return [self initWithStatus:GTJSCommandStatus_NO_RESULT message:nil];
}


- (GTJSPluginResult *)initWithStatus:(GTJSCommandStatus)statusOrdinal message:(id)theMessage
{
    self = [super init];
    if (self) {
        status = [NSNumber numberWithInt:statusOrdinal];
        message = theMessage;
    }
    return self;
}


#pragma mark 封装返回数据
+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
{
    return [[self alloc] initWithStatus:statusOrdinal message:nil];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                       messageAsString:(NSString *)theMessage
{
    return [[self alloc] initWithStatus:statusOrdinal message:theMessage];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                        messageAsArray:(NSArray *)theMessage
{
    return [[self alloc] initWithStatus:statusOrdinal message:theMessage];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal messageAsInt:(int)theMessage
{
    return [[self alloc] initWithStatus:statusOrdinal message:[NSNumber numberWithInt:theMessage]];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                       messageAsDouble:(double)theMessage
{
    return
    [[self alloc] initWithStatus:statusOrdinal message:[NSNumber numberWithDouble:theMessage]];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                         messageAsBool:(BOOL)theMessage
{
    return [[self alloc] initWithStatus:statusOrdinal message:[NSNumber numberWithBool:theMessage]];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                   messageAsDictionary:(NSDictionary *)theMessage
{
    return [[self alloc] initWithStatus:statusOrdinal message:theMessage];
}

+ (GTJSPluginResult *)resultWithStatus:(GTJSCommandStatus)statusOrdinal
                  messageToErrorObject:(int)errorCode
{
    NSDictionary *errDict = @{ @"code" : [NSNumber numberWithInt:errorCode] };
    return [[self alloc] initWithStatus:statusOrdinal message:errDict];
}


#pragma mark 将返回数据统一转化成JSON
- (NSString *)argumentsAsJSON
{
    id arguments = (self.message == nil ? [NSNull null] : self.message);
    
    //通过Array封装成JSON数组，然后去掉两头的括号
    NSArray *argumentsWrappedInArray = [NSArray arrayWithObject:arguments];
    NSString *argumentsJSON = [argumentsWrappedInArray cdv_JSONString];
    argumentsJSON = [argumentsJSON substringWithRange:NSMakeRange(1, [argumentsJSON length] - 2)];
    return argumentsJSON;
}


- (NSString *)toJSONString
{
    NSDictionary *dict = [NSDictionary
                          dictionaryWithObjectsAndKeys:self.status, @"status",
                          self.message ? self.message : [NSNull null], @"message", nil];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *resultString = nil;
    if (error != nil) {
        NSLog(@"toJSONString error: %@", [error localizedDescription]);
    } else {
        resultString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return resultString;
}

#pragma mark - 将处理结果封装成执行字符串
- (NSString *)toJsCallbackString:(NSString *)callbackId
{
    NSString *successCB = @"";
    NSString *argumentsAsJSON = [self argumentsAsJSON];
    argumentsAsJSON = [argumentsAsJSON stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if ([callbackId intValue] > 0) {
        successCB = [successCB stringByAppendingFormat:@"mapp.execGlobalCallback(%d,'%@');",
                     [callbackId intValue], argumentsAsJSON];
    } else {
        successCB =
        [successCB stringByAppendingFormat:@"window.%@('%@');", callbackId, argumentsAsJSON];
    }
    
    return successCB;
}

@end

