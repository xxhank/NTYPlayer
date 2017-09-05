//
//  AppSettings.h
//  Fibra
//
//  Created by wangchao9 on 2017/6/22.
//  Copyright © 2017年 wangchao9. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *uid;
@property (nonatomic, assign) BOOL        somethingPlaying;  ///< 影视正在播放
@property (nonatomic, copy) NSString     *apprunid;
@property (nonatomic, strong) NSString   *tags;
+ (instancetype)shared;
+ (NSString*)curentHost;
@end
