//
//  UIProgressView+WKWebView.m
//  Aspects
//
//  Created by liuxc on 2018/12/20.
//

#import "UIProgressView+WKWebView.h"
#import "GTWebViewController.h"
#import <objc/runtime.h>

@implementation UIProgressView (WKWebView)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        Method originalMethod = class_getInstanceMethod(self, @selector(setProgress:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(hook_setProgress:));
        method_exchangeImplementations(originalMethod, swizzledMethod);

        originalMethod = class_getInstanceMethod(self, @selector(setProgress:animated:));
        swizzledMethod = class_getInstanceMethod(self, @selector(hook_setProgress:animated:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)hook_setProgress:(float)progress {
    [self hook_setProgress:progress];

    [self checkHiddenWhenWebDidLoad];
}

- (void)hook_setProgress:(float)progress animated:(BOOL)animated {
    [self hook_setProgress:progress animated:animated];

    [self checkHiddenWhenWebDidLoad];
}

- (void)checkHiddenWhenWebDidLoad {
    if (!self.hiddenWhenWebDidLoad) {
        return;
    }

    float progress = self.progress;
    if (progress < 1) {
        if (self.hidden) {
            self.hidden = NO;
        }
    } else if (progress >= 1) {
        [UIView animateWithDuration:0.35 delay:0.15 options:7 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.hidden = YES;
                self.progress = 0.0;
                self.alpha = 1.0;

                //如果vc没被释放
                if (self.webViewController) {
                    if (self.webViewController.navigationType == GTWebViewControllerNavigationTypeBarItem) {
                        [self.webViewController updateNavigationItems];
                    }

                    if (self.webViewController.navigationType == GTWebViewControllerNavigationTypeToolItem) {
                        [self.webViewController updateToolbarItems];
                    }
                }
            }
        }];
    }
}

- (BOOL)hiddenWhenWebDidLoad {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setHiddenWhenWebDidLoad:(BOOL)hiddenWhenWebDidLoad {
    objc_setAssociatedObject(self, @selector(hiddenWhenWebDidLoad), @(hiddenWhenWebDidLoad), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GTBaseWebViewController *)webViewController {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWebViewController:(GTBaseWebViewController *)webViewController {
    objc_setAssociatedObject(self, @selector(webViewController), webViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end
