//
//  GTWebViewMacros.h
//  Pods
//
//  Created by liuxc on 2018/12/21.
//

#ifndef GT_REQUIRES_SUPER
#if __has_attribute(objc_requires_super)
#define GT_REQUIRES_SUPER __attribute__((objc_requires_super))
#else
#define GT_REQUIRES_SUPER
#endif
#endif

#ifndef GTWebViewControllerLocalizedString
#define GTWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"GTWebViewController", self.resourceBundle, comment)
#endif

#ifndef kGT404NotFoundHTMLPath
#define kGT404NotFoundHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"GTWebViewController")] pathForResource:@"GTWebViewController.bundle/html.bundle/404" ofType:@"html"]
#endif
#ifndef kGTNetworkErrorHTMLPath
#define kGTNetworkErrorHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"GTWebViewController")] pathForResource:@"GTWebViewController.bundle/html.bundle/neterror" ofType:@"html"]
#endif

/// URL key for 404 not found page.
static NSString *const kGT404NotFoundURLKey = @"gt_404_not_found";
/// URL key for network error page.
static NSString *const kGTNetworkErrorURLKey = @"gt_network_error";
/// Tag value for container view.
static NSUInteger const kContainerViewTag = 0x893147;
static NSString *POSTRequest = @"POST";
