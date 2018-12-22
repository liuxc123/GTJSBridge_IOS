//
//  GTAppDelegate.m
//  GTJSBridge
//
//  Created by liuxc123 on 12/11/2018.
//  Copyright (c) 2018 liuxc123. All rights reserved.
//

#import "GTAppDelegate.h"
#import "GTViewController.h"
#import "GTWebViewController.h"

@implementation GTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    [[UINavigationBar appearance] setBackIndicatorImage:[[UIImage imageNamed:@"back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];


    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    GTViewController *rootVC = [[GTViewController alloc] initWithNibName:nil bundle:nil];

//    GTWebViewController *rootVC = [[GTWebViewController alloc] initWithURLString:@"http://www.baidu.com"];


    GTUINavigationController *rootNavi = [[GTUINavigationController alloc] initWithRootViewController:rootVC];
    [self setupDefaultNavi:[rootNavi naviBarViewControllerForViewController:rootVC]];
    rootNavi.delegate = self;


//    UINavigationController *rootNavi = [[UINavigationController alloc] initWithRootViewController:rootVC];


    self.window.rootViewController = rootNavi;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)navigationController:(GTUINavigationController *)navigationController willAddAppBarViewController:(GTUIAppBarViewController *)appBarViewController asChildOfViewController:(UIViewController *)viewController
{
    [self setupDefaultNavi:appBarViewController];
}


- (void)setupDefaultNavi:(GTUIAppBarViewController *)appBarController {
    UIImageView *navImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navi_background"]];
    navImageView.frame = appBarController.headerView.frame;
    navImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [appBarController.headerView insertSubview:navImageView atIndex:0];
    appBarController.headerView.canOverExtend = NO;
    appBarController.navigationBar.titleFont = [UIFont systemFontOfSize:17];
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
