//
//  SystemAuthorityManager.h
//  SecondVoice
//
//  Created by RLY on 2019/4/20.
//  Copyright © 2019 深圳市最钱沿科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SystemAuthorities) {
    
    Authority_Video = 0,     //相机
    Authority_Library,       //相册
    Authority_Microphone,    //麦克风
    Authority_Location,      //地理位置
    Authority_AddressBook    //通讯录
};

@interface SystemAuthorityManager : NSObject

+ (instancetype)sharedManager;

/**
 *  判断有无权限
 */
- (BOOL)judgeAuthorization:(SystemAuthorities)systemAuthorities;

/**
 *  弹出请求
 */
- (void)requestAuthorization:(SystemAuthorities)systemAuthorities;

@end

NS_ASSUME_NONNULL_END
