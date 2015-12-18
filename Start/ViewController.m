//
//  ViewController.m
//  Start
//
//  Created by Alec Cursley on 15/12/2015.
//  Copyright © 2015 University of Warwick. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

bool webViewDidLoad = false;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hack up the User-Agent so the web app can tell it's running within an app
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Safari/App Start/1.0", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    self.webView.scrollView.bounces = false;
    
    [self loadWebView];
    
    [self installSecretRefreshGesture];
    
}

- (void)installSecretRefreshGesture {
    // Double-tap with three fingers to refresh the page
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(loadWebView)];
    
    gesture.numberOfTouchesRequired = 3;
    gesture.numberOfTapsRequired = 2;
    
    [self.view addGestureRecognizer:gesture];
}

- (void)loadWebView {
    self.tabBar.selectedItem = self.tabBar.items.firstObject;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:START_URL]];
    
    [self.webView loadRequest:request];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return webViewDidLoad ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSString *lowercaseTitle = item.title.lowercaseString;
    NSString *path = [NSString stringWithFormat:"/%@", lowercaseTitle];
    
    if ([lowercaseTitle isEqualToString:@"me"]) {
        path = @"/";
    }
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Store.dispatch({type: 'path.navigate', path: '%@'});", path]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    webViewDidLoad = true;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
