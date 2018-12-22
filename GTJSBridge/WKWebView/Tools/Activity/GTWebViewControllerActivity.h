//
//  GTWebViewControllerActivity.h
//  GTJSBridge
//
//  Created by liuxc on 2018/12/19.
//

#import <UIKit/UIKit.h>

@interface GTWebViewControllerActivity : UIActivity
/// URL to open.
@property (nonatomic, strong) NSURL *URL;
/// Scheme prefix value.
@property (nonatomic, strong) NSString *scheme;
@end

@interface GTWebViewControllerActivityChrome : GTWebViewControllerActivity @end
@interface GTWebViewControllerActivitySafari : GTWebViewControllerActivity @end
