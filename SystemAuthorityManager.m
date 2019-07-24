//
//  SystemAuthorityManager.m
//  SecondVoice
//
//  Created by RLY on 2019/4/20.
//  Copyright © 2019 深圳市最钱沿科技有限公司. All rights reserved.
//

#import "SystemAuthorityManager.h"
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

static SystemAuthorityManager *systemAuthorityManager = nil;

@interface SystemAuthorityManager ()

@property(nonatomic,strong) CLLocationManager *locationManager;

@end

@implementation SystemAuthorityManager

+ (instancetype)sharedManager {
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        systemAuthorityManager = [[SystemAuthorityManager alloc] init];
    });
    return systemAuthorityManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemAuthorityManager = [super allocWithZone:zone];
    });
    return systemAuthorityManager;
}

-(id)copyWithZone:(struct _NSZone *)zone{
    return systemAuthorityManager;
}

/**
 *  判断有无权限
 */
- (BOOL)judgeAuthorization:(SystemAuthorities)systemAuthorities{
    
    switch (systemAuthorities) {
            
        case Authority_Video:{
            
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                
                NSString *mediaType = AVMediaTypeVideo;
                AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                
                if(authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted){
                    
                    NSString *tips = [NSString stringWithFormat:@"无相机权限，请在iPhone的”设置-隐私-相机“选项中，允许“秒音”访问您的相机"];
                    [self executeAlterTips:tips];
                    return NO;
                }else{
                    return YES;
                }
            }
        }
            break;
        case Authority_Library:{
            
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                
                PHAuthorizationStatus  authorizationStatus = [PHPhotoLibrary   authorizationStatus];
                if (authorizationStatus == PHAuthorizationStatusDenied || authorizationStatus == PHAuthorizationStatusRestricted) {
                    
                    NSString *tips = [NSString stringWithFormat:@"无相册权限，请在iPhone的”设置-隐私-相册“选项中，允许“秒音”访问您的相册"];
                    [self executeAlterTips:tips];
                    return NO;
                }else{
                    return YES;
                }
            }
        }
            break;
        case Authority_Microphone:{
//            BOOL isCanRecord = [self canRecord];
//            if ( isCanRecord == NO) {
//
//                NSString *tips = [NSString stringWithFormat:@"无麦克风权限，请在iPhone的”设置-隐私-麦克风“选项中，允许“秒音”访问您的麦克风"];
//                [self executeAlterTips:tips];
//                return NO;
//            }else {
//
//                return YES;
//            }
            return [self canRecord];
        }
            break;
        case Authority_Location:{
            
            CLAuthorizationStatus authStatus = CLLocationManager.authorizationStatus;
            if ( authStatus == kCLAuthorizationStatusDenied) {
                
                NSString *tips = [NSString stringWithFormat:@"无定位权限，请在iPhone的”设置-隐私-定位“选项中，允许“秒音”访问您的定位"];
                [self executeAlterTips:tips];
                return NO;
            }else if(authStatus == kCLAuthorizationStatusRestricted ){
                
                [self executeAlterTips:@"权限受限"];
                return NO;
            }else {
                
                return YES;
            }
        }
            break;
        case Authority_AddressBook:{
            
            ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
            NSString *tips = [NSString stringWithFormat:@"无通讯录权限，请在iPhone的”设置-隐私-联系人“选项中，允许“秒音”访问您的通讯录"];
            
            if ( authStatus ==kABAuthorizationStatusDenied){  //无权限
                
                [self executeAlterTips:tips];
                return NO;
            }else if (authStatus == kABAuthorizationStatusRestricted ){ //收限制
                
                [self executeAlterTips:@"权限受限"];
                return NO;
            }else{
                return YES;
            }
        }
            break;
        default:break;
    }
    return YES;
}

/**
 *  弹出请求
 */
- (void)requestAuthorization:(SystemAuthorities)systemAuthorities{
    
    switch (systemAuthorities) {
            
        case Authority_Video:{
            
            //弹出请求：使用摄像机权限
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
            }];
        }
            break;
            
        case Authority_Library:{
            
            //弹出请求：访问相册权限
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
            }];
        }
            break;
            
        case Authority_Microphone:{
            
            if (![self canRecord]) {
                
                NSString *tips = [NSString stringWithFormat:@"无麦克风权限，请在iPhone的”设置-隐私-麦克风“选项中，允许“秒音”访问您的麦克风"];
                [self executeAlterTips:tips];
            }
        }
            break;
        case Authority_Location:{
            
            _locationManager = [[CLLocationManager alloc] init];
            [_locationManager requestWhenInUseAuthorization];
        }
            break;
        
        case Authority_AddressBook:{
            
            __block ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            if (addressBook == NULL) {
                [self executeAlterTips:@""];
            }
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                
                if (addressBook) {
                    CFRelease(addressBook);
                    addressBook = NULL;
                }
            });
        }
            break;
        default:break;
    }
}

//是否有麦克风权限
- (BOOL)canRecord{
    __block BOOL bCanRecord = YES;
    if ([[UIDevice currentDevice] systemVersion].floatValue > 7.0){
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    return bCanRecord;
}

//提示弹框
- (void)executeAlterTips:(NSString *)alterTips{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *alterContent = @"提示";
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alterContent message:alterTips preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"去设置" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancel];
        [alertController addAction:action];
        [[self currentViewController] presentViewController:alertController animated:YES completion:nil];
    });
}

/**
 *  Tool
 */
- (UIViewController*) currentViewController {
    // Find best view controller
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

- (UIViewController*) findBestViewController:(UIViewController*)vc{
    if (vc.presentedViewController) {
        // Return presented view controller
        return [self findBestViewController:vc.presentedViewController];
    }
    else if ([vc isKindOfClass:[UISplitViewController class]]) {
        // Return right hand side
        UISplitViewController *svc = (UISplitViewController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.viewControllers.lastObject];
        else
            return vc;
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        // Return top view
        UINavigationController *svc = (UINavigationController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.topViewController];
        else
            return vc;
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // Return visible view
        UITabBarController *svc = (UITabBarController*) vc;
        if (svc.viewControllers.count > 0)
            return [self findBestViewController:svc.selectedViewController];
        else
            return vc;
    } else {
        // Unknown view controller type, return last child view controller
        return vc;
    }
}

@end
