//
//  GTViewController.m
//  GTJSBridge
//
//  Created by liuxc123 on 12/11/2018.
//  Copyright (c) 2018 liuxc123. All rights reserved.
//

#import "GTViewController.h"
#import "GTWebViewController.h"
#import "GTNavigationController.h"

@interface GTViewController ()

@end

@implementation GTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = UIColor.whiteColor;


    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:btn];

    btn.frame = self.view.bounds;

    [btn setTitle:@"点击打开一个网页" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(openWebView) forControlEvents:UIControlEventTouchUpInside];

}

- (void)openWebView
{

    GTWebViewController *webVC = [[GTWebViewController alloc] initWithURLString:@"http://debug.api.webus.vip/index/other/help"];
    [self.navigationController pushViewController:webVC animated:YES];

//    GTUINavigationController *navi = [[GTUINavigationController alloc] initWithRootViewController:webVC];
//    [self presentViewController:navi animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
