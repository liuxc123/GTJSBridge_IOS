//
//  GTWebViewControllerActivity.m
//  GTJSBridge
//
//  Created by liuxc on 2018/12/19.
//

#import "GTWebViewControllerActivity.h"

@implementation GTWebViewControllerActivity
- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (UIImage *)activityImage {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *resourcePath = [bundle pathForResource:@"GTWebViewController" ofType:@"bundle"] ;

    if (resourcePath){
        NSBundle *bundle2 = [NSBundle bundleWithPath:resourcePath];
        if (bundle2){
            bundle = bundle2;
        }
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return  [UIImage imageNamed:[self.activityType stringByAppendingString:@"-iPad"] inBundle:bundle compatibleWithTraitCollection:nil];

    else
        return [UIImage imageNamed:self.activityType inBundle:bundle compatibleWithTraitCollection:nil];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            self.URL = activityItem;
        }
    }
}
@end

@implementation GTWebViewControllerActivityChrome
- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *resourcePath = [bundle pathForResource:@"GTWebViewController" ofType:@"bundle"] ;

    if (resourcePath){
        NSBundle *bundle2 = [NSBundle bundleWithPath:resourcePath];
        if (bundle2){
            bundle = bundle2;
        }
    }

    return NSLocalizedStringFromTableInBundle(@"OpenInChrome", @"GTWebViewController", bundle, @"Open in Chrome");

}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:self.schemePrefix]]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    NSString *openingURL;
    if (@available(iOS 9.0, *)) {
        openingURL = [self.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        openingURL = [self.URL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    }

    NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.schemePrefix, openingURL]];

    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:activityURL options:@{} completionHandler:NULL];
    } else {
        [[UIApplication sharedApplication] openURL:activityURL];
    }

    [self activityDidFinish:YES];
}
@end

@implementation GTWebViewControllerActivitySafari
- (NSString *)activityTitle {

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *resourcePath = [bundle pathForResource:@"GTWebViewController" ofType:@"bundle"] ;

    if (resourcePath){
        NSBundle *bundle2 = [NSBundle bundleWithPath:resourcePath];
        if (bundle2){
            bundle = bundle2;
        }
    }

    return NSLocalizedStringFromTableInBundle(@"OpenInSafari", @"GTWebViewController", bundle, @"Open in Safari");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    BOOL completed = [[UIApplication sharedApplication] openURL:self.URL];
    [self activityDidFinish:completed];
}
@end

