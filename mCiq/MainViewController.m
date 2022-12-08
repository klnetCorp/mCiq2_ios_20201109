//
//  MainViewController.m
//  mCiq
//
//  Created by juis on 2019. 1. 25..
//  Copyright © 2019년 juis. All rights reserved.
//

#import "MainViewController.h"
#import "DataSet.h"
#import "OpenUDID.h"
#import <WebKit/WebKit.h>
#import <sys/utsname.h>
#import <CommonCrypto/CommonCrypto.h>
@interface MainViewController ()

@end

@implementation UIWebView (Javascript)
static BOOL diagStat = NO;
static BOOL diagStat2 = NO;

- (void)webView:(UIWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"확인" otherButtonTitles: nil];
    [alert show];
}

- (BOOL)webView:(UIWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(id *)frame {
    diagStat2 = NO;
    UIAlertView *confirmDiag = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:NSLocalizedString(@"취소", @"취소") otherButtonTitles:NSLocalizedString(@"확인", @"확인"), nil];
    [confirmDiag show];
    
    //버튼 누르기전까지 지연.
    CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 7.) {
        while (diagStat2 == NO) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
        }
    } else {
        while (diagStat2 == NO && confirmDiag.superview != nil) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
        }
    }
    return diagStat;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        diagStat = NO;
        diagStat2 = YES;
    } else if (buttonIndex == 1) {
        diagStat = YES;
        diagStat2 = YES;
    }
}

@end

@implementation MainViewController
@synthesize webView01, iv_intro, constraint_keyboard_height;

- (void)viewDidLoad {
    [super viewDidLoad];
    webView01.delegate = self;
    
    
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleIdentifier = [bundleInfo valueForKey:@"CFBundleIdentifier"];
    NSURL *lookupURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", bundleIdentifier]];
    NSData *lookupResults = [NSData dataWithContentsOfURL:lookupURL];
    NSDictionary *jsonResults = [NSJSONSerialization JSONObjectWithData:lookupResults options:0 error:nil];
    
    NSUInteger resultCount = [[jsonResults objectForKey:@"resultCount"] integerValue];
    

    NSString *sSignHash = [self md5:MAIN_URL];
    NSString *getHash = [self sendDataToServer];
   
    BOOL rootingCheck = [self checkRooting];
    [DataSet sharedDataSet].isMode = IS_MODE;
    [DataSet sharedDataSet].mainURL = MAIN_URL;
    [DataSet sharedDataSet].pushURL = PUSH_URL;
    
    if ([[DataSet sharedDataSet].isMode isEqualToString:@"D"]) {
        //개발 테스트용은 앱스토어 배포가 아니므로 무조건 통과시킨다.
        getHash = sSignHash;
    }
    
    
    if(!rootingCheck) {
        NSString *msg = [NSString stringWithFormat:@"루팅된 단말기 입니다. \n개인정보 유출의 위험성이 있으므로 \n프로그램을 종료합니다."];
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:@"알림"
                                      message:msg
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"확인"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
            exit(0);
                                   }];
        [alert addAction:okAction];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
        });
    }
    
    if(![sSignHash isEqualToString:getHash]) {
    
        NSString *msg = [NSString stringWithFormat:@"프로그램 무결성에 위배됩니다. \nAppStore 내에서 \n 설치하시기 바랍니다."];
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:@"알림"
                                      message:msg
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"확인"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
            exit(0);
                                   }];
        [alert addAction:okAction];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
        });
    }
    NSLog(@"resultCount : %lu", (unsigned long)resultCount);
    if (resultCount){
        NSDictionary *appDetails = [[jsonResults objectForKey:@"results"] firstObject];
        NSString *latestVersion = [appDetails objectForKey:@"version"];
        NSString *currentVersion = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
#if DEBUG
        NSLog(@"latestVersion====%@",latestVersion);
        NSLog(@"currentVersion====%@",currentVersion);
#endif
        
        //앱스토어에 올라간 버전과 빌드버전이 다를경우 팝업을 출력한다.
        if(![latestVersion isEqualToString:currentVersion]){
            NSString *versionmsg = [NSString stringWithFormat:@"새로운버전(%@)이 나왔습니다. 업데이트 하시겠습니까?",latestVersion];
            
            UIAlertController * alert =  [UIAlertController
                                          alertControllerWithTitle:@"알림"
                                          message:versionmsg
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"확인"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"https://itunes.apple.com/app/id1460559150?mt=8"]];
                                       }];
            
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:@"취소"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
                                           }];
            
            [alert addAction:okAction];
            [alert addAction:cancelAction];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }
    

    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/newmobile/login.jsp",mainURL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1.0f];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/newmobile/login.jsp",MAIN_URL]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView01 loadRequest:request];
#if DEBUG
    NSLog(@"udid:%@", [OpenUDID value]);
#endif
}


- (void) callPush {
    if([DataSet sharedDataSet].isLogin && [DataSet sharedDataSet].pushDict != nil ) {
        NSString *userid = [[DataSet sharedDataSet].pushDict objectForKey:@"userid"];
        NSString *push_id = [[DataSet sharedDataSet].pushDict objectForKey:@"push_id"];
        NSString *message = [[DataSet sharedDataSet].pushDict objectForKey:@"message"];
        
        if([[DataSet sharedDataSet].userid isEqualToString:userid]) {
            UIAlertController * alert =  [UIAlertController
                                          alertControllerWithTitle:@"알림"
                                          message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"확인"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           [self.webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:goPush('%@');",push_id]];
                                           [DataSet sharedDataSet].pushDict = nil;
                                       }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [DataSet sharedDataSet].pushDict = nil;
                                                                     //[alert dismissViewControllerAnimated:YES completion:nil];
                                                                 }];
            [alert addAction:okAction];
            [alert addAction:cancelAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

+ (MainViewController *)sharedMainView
{
    static MainViewController *singletonClass = nil;
    if(singletonClass == nil)
    {
        @synchronized(self)
        {
            if(singletonClass == nil)
            {
                singletonClass = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
            }
        }
    }
    return singletonClass;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    //접속경로
    NSString *mainURL = [DataSet sharedDataSet].mainURL;
    NSString *pushURL = [DataSet sharedDataSet].pushURL;
    
    
    NSString *requestString = [[request URL] absoluteString];
#if DEBUG
    NSLog(@"requestString : %@", requestString);
#endif
    if ([requestString hasSuffix:@".pdf"] || [requestString hasSuffix:@".txt"] || [requestString hasSuffix:@".PDF"] || [requestString hasSuffix:@".TXT"] || [requestString hasSuffix:@".TEXT"] || [requestString hasSuffix:@".text"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:requestString]];
        return NO;
    }
    
    //이전 버튼
    if ([requestString hasPrefix:@"hybridappurlback://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridappurlback://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
#if DEBUG
        NSLog(@"urlback : %@", jsString);
#endif
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",mainURL, jsString]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1.0f];
        [webView01 loadRequest:request];
        
        return NO;
    }
    
    //자동로그인 처리
    if ([requestString hasPrefix:@"hybridappautologinresult://"]) {
        NSArray *jsDataArray2 = [requestString componentsSeparatedByString:@"hybridappautologinresult://"];
        NSArray *jsDataArray = [[jsDataArray2 objectAtIndex:1] componentsSeparatedByString:@"&&"];
        NSString *jsString1 = [jsDataArray objectAtIndex:0];
        NSString *jsString2 = [jsDataArray objectAtIndex:1];
        
        if ([jsString1 isEqualToString:@"success"]) {
            [DataSet sharedDataSet].userid = jsString2;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/newmobile/main.jsp",mainURL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:0.0f];
            [webView01 loadRequest:request];
            [iv_intro setHidden:YES];
            [webView01 setHidden:NO];
            struct utsname systemInfo;
            uname(&systemInfo);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            NSError *error;
            NSString *path01 = [documentsDirectory stringByAppendingPathComponent:@"jpp.plist"];
            NSFileManager *fileManager01 = [NSFileManager defaultManager];
            if (![fileManager01 fileExistsAtPath: path01])
            {
                NSString *bundle = [[NSBundle mainBundle] pathForResource:@"jpp" ofType:@"plist"];
                
                [fileManager01 copyItemAtPath:bundle toPath: path01 error:&error];
            }
            NSMutableDictionary *jppData = [[NSMutableDictionary alloc] initWithContentsOfFile:path01];
            NSString *token = (NSString *)[jppData objectForKey:@"token"];
            
            NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
            
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPMobileAppId('%@');",@"MCIQ2"]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOs('%@');",@"fcm_ios"]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceId('%@');",[OpenUDID value]]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPToken('%@');",token]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPUserId('%@');",DataSet.sharedDataSet.userid]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPPushUrl('%@');",PUSH_URL]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPModelName('%@');",model]];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOsVersion('%@');",[[UIDevice currentDevice] systemVersion]]];
            
            [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setPush('Y')"];
        } else { //실패했을 경우
            [iv_intro setHidden:YES];
            [webView01 setHidden:NO];
        }
        return NO;
    }
    
    //로그인 결과저장
    if ([requestString hasPrefix:@"hybridappautoregister://"]) {
        NSArray *jsDataArray2 = [requestString componentsSeparatedByString:@"hybridappautoregister://"];
        NSArray *jsDataArray = [[jsDataArray2 objectAtIndex:1] componentsSeparatedByString:@"&&"];
        
        NSString *jsString1 = [jsDataArray objectAtIndex:0];
        NSString *jsString2 = [jsDataArray objectAtIndex:1];
        NSString *jsString3 = [jsDataArray objectAtIndex:2];
        
#if DEBUG
        NSLog(@"id : %@", jsString1);
        NSLog(@"isAutoLogin : %@", jsString2);
        NSLog(@"deviceId : %@", jsString3);
#endif
        
        [DataSet sharedDataSet].userid = jsString1;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"autologin" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        [authData setObject:jsString1 forKey:@"vid"];
        //[authData setObject:jsString3 forKey:@"vpassword"];
        [authData removeObjectForKey:@"vpassword"];
        
        if([jsString2 isEqualToString:@"Y"]) {
            [authData setObject:[NSNumber numberWithBool:YES] forKey:@"isautologin"];
        } else {
            [authData setObject:[NSNumber numberWithBool:NO] forKey:@"isautologin"];
        }
        DataSet.sharedDataSet.userid = jsString1;
        
        [authData writeToFile:path atomically:YES];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString *path01 = [documentsDirectory stringByAppendingPathComponent:@"jpp.plist"];
        NSFileManager *fileManager01 = [NSFileManager defaultManager];
        if (![fileManager01 fileExistsAtPath: path01])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"jpp" ofType:@"plist"];
            
            [fileManager01 copyItemAtPath:bundle toPath: path01 error:&error];
        }
        NSMutableDictionary *jppData = [[NSMutableDictionary alloc] initWithContentsOfFile:path01];
        NSString *token = (NSString *)[jppData objectForKey:@"token"];
        
        NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPMobileAppId('%@');",@"MCIQ2"]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOs('%@');",@"fcm_ios"]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceId('%@');",[OpenUDID value]]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPToken('%@');",token]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPUserId('%@');",DataSet.sharedDataSet.userid]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPPushUrl('%@');",PUSH_URL]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPModelName('%@');",model]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOsVersion('%@');",[[UIDevice currentDevice] systemVersion]]];
        
        [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setPush('Y')"];
        
        //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/newmobile/main.jsp",mainURL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:1.0f];
        
        //[webView01 loadRequest:request];
        return NO;
    }
    
    //세션끊겼을때 자동로그인
    if ([requestString hasPrefix:@"hybridappautorelogin://"]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        NSNumber * nisAutoLogin = [authData objectForKey:@"isautologin"];
        Boolean isAutoLogin = [nisAutoLogin boolValue];
        NSString *vid = [authData objectForKey:@"vid"];
        //NSString *vpassword = [authData objectForKey:@"vpassword"];
        NSString *deviceId = [OpenUDID value];
        NSString *autoLoginYn = @"N";
        if (isAutoLogin) {
            autoLoginYn = @"Y";
        }
        
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setIsAutoLogin('%@', '%@','%@');",autoLoginYn, deviceId, vid]];
        
        if ([DataSet sharedDataSet].isLogin && isAutoLogin && vid.length != 0 && deviceId.length != 0) {
            //[webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setIsAutoLogin('Y');"];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:appAutoLogin('%@','%@');",vid, deviceId]];
        }
        return NO;
    }
    
    //대표코드
    if ([requestString hasPrefix:@"hybridappdstprtcodeinit://"]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"dstprt.plist"];
        NSMutableDictionary *dstPrtData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        NSString *dstPrtCode = [dstPrtData objectForKey:@"dstPrtCode"];
        NSString *dstPrtName = [dstPrtData objectForKey:@"dstPrtName"];
        
        if(dstPrtCode.length  == 0 ) {
            dstPrtCode = @"";
            dstPrtName = @"";
        }
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:fn_pop_setDstprtCode_init('%@','%@');",dstPrtCode, dstPrtName]];
        return NO;
    }
    
    //환경설정세팅
    if ([requestString hasPrefix:@"hybridappinitconfig://"]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        NSNumber * nisAutoLogin = [authData objectForKey:@"isautologin"];
        Boolean isAutoLogin = [nisAutoLogin boolValue];
        
        if(isAutoLogin) {
            [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setConfigIsAutoLogin('Y');"];
        }
        
        NSString *path01 = [documentsDirectory stringByAppendingPathComponent:@"dstprt.plist"];
        NSMutableDictionary *dstPrtData = [[NSMutableDictionary alloc] initWithContentsOfFile:path01];
        NSString * dstPrtCode = [dstPrtData objectForKey:@"dstPrtCode"];
        NSString * dstPrtName = [dstPrtData objectForKey:@"dstPrtName"];
        
        if(dstPrtCode.length != 0) {
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setDstprtCode('%@','%@');", dstPrtCode, dstPrtName]];
        }
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSError *error;
        NSString *path02 = [documentsDirectory stringByAppendingPathComponent:@"jpp.plist"];
        NSFileManager *fileManager02 = [NSFileManager defaultManager];
        if (![fileManager02 fileExistsAtPath: path02])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"jpp" ofType:@"plist"];
            
            [fileManager02 copyItemAtPath:bundle toPath: path02 error:&error];
        }
        NSMutableDictionary *jppData = [[NSMutableDictionary alloc] initWithContentsOfFile:path02];
        NSString *token = (NSString *)[jppData objectForKey:@"token"];
        
        NSString *model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPMobileAppId('%@');",@"MCIQ2"]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOs('%@');",@"fcm_ios"]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceId('%@');",[OpenUDID value]]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPToken('%@');",token]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPUserId('%@');",DataSet.sharedDataSet.userid]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPPushUrl('%@');",PUSH_URL]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPModelName('%@');",model]];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setJPPDeviceOsVersion('%@');",[[UIDevice currentDevice] systemVersion]]];
        
        [webView01 stringByEvaluatingJavaScriptFromString:@"javascript:onLoadInit();"];
                            
        return NO;
    }
    
    //자동로그인 여부 설정에 저장
    if ([requestString hasPrefix:@"hybridappconfigsetautologin://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridappconfigsetautologin://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"autologin" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        if([jsString isEqualToString:@"Y"]) {
            [authData setObject:[NSNumber numberWithBool:YES] forKey:@"isautologin"];
        } else {
            [authData setObject:[NSNumber numberWithBool:NO] forKey:@"isautologin"];
        }
        
        [authData writeToFile:path atomically:YES];
        return NO;
    }
    
    //대표코드 설정
    if ([requestString hasPrefix:@"hybridappdstprtcode://"]) {
        
        NSArray *jsDataArray2 = [requestString componentsSeparatedByString:@"hybridappdstprtcode://"];
        NSArray *jsDataArray = [[jsDataArray2 objectAtIndex:1] componentsSeparatedByString:@"&&"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"dstprt.plist"];
        
        NSString *dstPrtCode = [jsDataArray objectAtIndex:0];
 
        NSString *dstPrtName = [[jsDataArray objectAtIndex:1] stringByRemovingPercentEncoding];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"dstprt" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *dstPrtData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        [dstPrtData setObject:dstPrtCode forKey:@"dstPrtCode"];
        [dstPrtData setObject:dstPrtName forKey:@"dstPrtName"];
        [dstPrtData writeToFile:path atomically:YES];
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setDstprtCode('%@','%@');", dstPrtCode, dstPrtName]];
        return NO;
    }
    
    //URL이동
    if ([requestString hasPrefix:@"hybridappgoweburl://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridappgoweburl://"];
        NSString *url = [jsDataArray objectAtIndex:1];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",mainURL, url]]];
        return NO;
    }
    
    //앱링크
    if ([requestString hasPrefix:@"hybridapplink://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridapplink://"];
        NSString *url = [jsDataArray objectAtIndex:1];
        NSString *appUrl = [NSString stringWithFormat:@"https://itunes.apple.com/kr/app/%@", url];
        NSLog(@"appUrl : %@", appUrl);
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:appUrl]];
        return NO;
    }
    
    if ([requestString hasPrefix:@"hybridsetchangemode://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridsetchangemode://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        
        if ([[DataSet sharedDataSet].isMode isEqualToString:@"D"]) {
            mainURL = MAIN_REAL_URL;
            pushURL = PUSH_REAL_URL;
            [DataSet sharedDataSet].isMode = @"P";
        } else {
            mainURL = MAIN_TEST_URL;
            pushURL = PUSH_TEST_URL;
            [DataSet sharedDataSet].isMode = @"D";
        }
        [DataSet sharedDataSet].mainURL = mainURL;
        [DataSet sharedDataSet].pushURL = pushURL;
        [DataSet sharedDataSet].isLogin = false;
    
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",mainURL, jsString]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:0.0f];
        [webView01 loadRequest:request];
        
        return NO;
    }
    
    //로그아웃
    if ([requestString hasPrefix:@"hybridapplogout://"]) {
        NSArray *jsDataArray = [requestString componentsSeparatedByString:@"hybridapplogout://"];
        NSString *jsString = [jsDataArray objectAtIndex:1];
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath: path])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"autologin" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path error:&error];
        }
        
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        [authData setObject:[NSNumber numberWithBool:NO] forKey:@"isautologin"];
        [authData writeToFile:path atomically:YES];
        
        [DataSet sharedDataSet].isLogin = false;
        
        NSString *path01 = [documentsDirectory stringByAppendingPathComponent:@"dstprt.plist"];
        if (![fileManager fileExistsAtPath: path01])
        {
            NSString *bundle = [[NSBundle mainBundle] pathForResource:@"dstprt" ofType:@"plist"];
            
            [fileManager copyItemAtPath:bundle toPath: path01 error:&error];
        }
        NSMutableDictionary *dstprtData = [[NSMutableDictionary alloc] initWithContentsOfFile:path01];
        
        [dstprtData setObject:@"" forKey:@"dstPrtCode"];
        [dstprtData setObject:@"" forKey:@"dstPrtName"];
        [dstprtData writeToFile:path01 atomically:YES];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",mainURL, jsString]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:0.0f];
        [webView01 loadRequest:request];
        
        return NO;
    }
    
    
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *currentURL = webView.request.URL.absoluteString;
#if DEBUG
    NSLog(@"currentURL : %@",currentURL);
#endif
    NSRange range_login;
    range_login = [currentURL rangeOfString:@"/newmobile/login.jsp"];
    
    if (range_login.location != NSNotFound) {
        [DataSet sharedDataSet].isLogin = false;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"autologin.plist"];
        NSMutableDictionary *authData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        
        NSNumber * nisAutoLogin = [authData objectForKey:@"isautologin"];
        Boolean isAutoLogin = [nisAutoLogin boolValue];
        NSString *vid = [authData objectForKey:@"vid"];
        //NSString *vpassword = [authData objectForKey:@"vpassword"];
        NSString *deviceId = [OpenUDID value];
        NSString *autoLoginYn = @"N";
        if (isAutoLogin) {
            autoLoginYn = @"Y";
        }
        
        [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:setIsAutoLogin('%@', '%@','%@');",autoLoginYn, deviceId, vid]];
        
        if ([DataSet sharedDataSet].isLogin && isAutoLogin && vid.length != 0 && deviceId.length != 0) {
            //[webView01 stringByEvaluatingJavaScriptFromString:@"javascript:setIsAutoLogin('Y');"];
            [webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:appAutoLogin('%@','%@');",vid, deviceId]];
        } else {
            [iv_intro setHidden:YES];
            [webView01 setHidden:NO];
        }
    }
    
    NSRange range_main;
    range_main = [currentURL rangeOfString:@"/newmobile/main.jsp"];
    
    if (range_main.location != NSNotFound) {
        [DataSet sharedDataSet].isLogin = true;
        [iv_intro setHidden:YES];
        [webView01 setHidden:NO];
        if([DataSet sharedDataSet].isLogin && [DataSet sharedDataSet].pushDict != nil ) {
            NSString *userid = [[DataSet sharedDataSet].pushDict objectForKey:@"userid"];
            NSString *push_id = [[DataSet sharedDataSet].pushDict objectForKey:@"push_id"];
            NSString *message = [[DataSet sharedDataSet].pushDict objectForKey:@"message"];
            
            if([[DataSet sharedDataSet].userid isEqualToString:userid]) {
                UIAlertController * alert =  [UIAlertController
                                              alertControllerWithTitle:@"알림"
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction
                                           actionWithTitle:@"확인"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
                                               [self.webView01 stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"javascript:goPush('%@');",push_id]];
                                               [DataSet sharedDataSet].pushDict = nil;
                                           }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                         [DataSet sharedDataSet].pushDict = nil;
                                                                         //[alert dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                [alert addAction:okAction];
                [alert addAction:cancelAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }
}

- (NSString *)sendDataToServer{
    __block NSString *returnValue;
    
    
    //접속경로
    NSString *mainURL = [DataSet sharedDataSet].mainURL;
    NSString *pushURL = [DataSet sharedDataSet].pushURL;
    
    NSUInteger length = [mainURL length];
//     해시코드 서버로직 개발 완료시 도메인 수정
       NSString *getURL = [NSString stringWithFormat:@"%@/newmobile/selectMobileHashKey.do?app_id=MCIQ&app_os=ios&app_version=%lu",mainURL,(unsigned long)length];
    
    
    NSURL* url = [NSURL URLWithString:getURL];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    NSError* error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil  error:&error];
    
    if(data != nil) {
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        returnValue = [dic objectForKey:@"hashCode"];
    }
    
    return returnValue;
}


- (NSString *)md5:(NSString *)input {
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i=0; i < CC_MD5_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x",digest[i]];
    ;
    return output;
}
- (BOOL)checkRooting {
    BOOL returnValue = YES;
    NSArray *checkList=[NSArray arrayWithObjects:
                         @"/Applications/Cydia.app",
                         @"/Applications/RockApp.app",
                         @"/Applications/Icy.app",
                         @"/usr/sbin/sshd",
                         @"/usr/bin/sshd",
                         @"/usr/libexec/sftp-server",
                         @"/Applications/WinterBoard.app",
                         @"/Applications/SBSettings.app",
                         @"/Applications/MxTube.app",
                         @"/Applications/IntelliScreen.app",
                         @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                         @"/Applications/FakeCarrier.app",
                         @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                         @"/private/var/lib/apt",
                         @"/Applications/blackra1n.app",
                         @"/private/var/stash",
                         @"/private/var/mobile/Library/SBSettings/Themes",
                         @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                         @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                         @"/private/var/tmp/cydia.log",
                         @"/private/var/lib/cydia",
                         nil];
    if(!TARGET_IPHONE_SIMULATOR) {
        for (NSString *filePath in checkList) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
                returnValue = NO;
                break;
            }
        }
    }
    return returnValue;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"error.code : %ld", (long)error.code);
    
    //접속경로
    NSString *mainURL = [DataSet sharedDataSet].mainURL;
    NSString *pushURL = [DataSet sharedDataSet].pushURL;
    
    if(error.code == 999 || error.code == -999) {
        
    } else if(error.code == -1001 || error.code == 1001) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/newmobile/main.jsp",mainURL]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:0.0f];
        [webView01 loadRequest:request];
    } else {
        [iv_intro setHidden:YES];
        [webView01 setHidden:NO];
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:@"오류"
                                      message:error.localizedDescription
                                      preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"확인"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       NSLog(@"OK action");
                                   }];
        
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    NSLog(@"Error : %@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
