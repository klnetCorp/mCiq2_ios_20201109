//
//  MainViewController.h
//  mCiq
//
//  Created by juis on 2019. 1. 25..
//  Copyright © 2019년 juis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>


@interface MainViewController : UIViewController <UIWebViewDelegate, UNUserNotificationCenterDelegate, UIScrollViewDelegate>

+ (MainViewController *)sharedMainView;
@property (strong, nonatomic) IBOutlet UIWebView *webView01;
@property (weak, nonatomic) IBOutlet UIImageView *iv_intro;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraint_keyboard_height;

- (void) callPush;

@end
