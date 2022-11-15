//
//  DataSet.h
//  MGW
//
//  Created by user on 11. 3. 18..
//  Copyright 2011 juis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#define MAIN_URL @"https://mciq.plism.com"
//#define MAIN_URL @"https://devmciq.plism.com"


#define PUSH_URL @"https://push.plism.com"
//#define PUSH_URL @"https://testpush.plism.com"
#define APPID @"mCiq"


@interface DataSet : NSObject {
    
}

@property(nonatomic) Boolean isLogin;
@property(nonatomic) Boolean isBackground;
@property(nonatomic, strong) NSDictionary *pushDict;
@property (nonatomic, strong) NSString *userid;
@property (nonatomic, strong) NSString *deviceTokenID;
@property(nonatomic) Boolean isAutoLogin;
@property (nonatomic, strong) NSString *seq;


+(DataSet *)sharedDataSet;

@end
