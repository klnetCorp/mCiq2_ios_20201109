//
//  DataSet.m
//  MGW
//
//  Created by user on 11. 3. 18..
//  Copyright 2011 juis. All rights reserved.
//

#import "DataSet.h"

@implementation DataSet

@synthesize isLogin, userid, pushDict, isAutoLogin, isBackground, deviceTokenID, seq;

-(void)CommonSetting {
    
}

+ (DataSet *)sharedDataSet
{
    static DataSet *singletonClass = nil;
    if(singletonClass == nil)
    {
        @synchronized(self)
        {
            if(singletonClass == nil)
            {
                singletonClass = [[self alloc] init];
            }
        }
    }
    return singletonClass;
}


@end
