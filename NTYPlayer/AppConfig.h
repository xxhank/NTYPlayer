//
//  AppConfig.h
//  Fibra
//
//  Created by wangchao9 on 2017/6/22.
//  Copyright © 2017年 wangchao9. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppConfig : NSObject
@property (nonatomic, readonly, strong) NSDictionary *configs;
@property (nonatomic, strong) NSString               *apiHost;
@property (nonatomic, strong) NSString               *reportHost;
@property (nonatomic, strong) NSString               *searchReportHost;
+ (instancetype)shared;
@end
