//
//  ViewController.h
//  Start
//
//  Created by Alec Cursley on 15/12/2015.
//  Copyright © 2015 University of Warwick. All rights reserved.
//

#import <UIKit/UIKit.h>

#define START_URL @"https://swordfish.warwick.ac.uk"

@interface ViewController : UIViewController <UIWebViewDelegate, UITabBarDelegate>

@property(nonatomic, strong) IBOutlet UIWebView *webView;
@property(nonatomic, strong) IBOutlet UITabBar *tabBar;

@end

