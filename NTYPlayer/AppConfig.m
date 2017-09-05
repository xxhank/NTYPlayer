//
//  AppConfig.m
//  Fibra
//
//  Created by wangchao9 on 2017/6/22.
//  Copyright © 2017年 wangchao9. All rights reserved.
//

#import "AppConfig.h"


@interface AppConfig ()
@property (nonatomic, strong) NSDictionary *configs;
@end
@implementation AppConfig

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AppConfig      *instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *path = [Path pathForResource:@"config.plist"];
        _configs = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return self;
}

- (NSString*)apiHost {
    return self.configs[@"apiUrlBase"];
}
- (NSString*)reportHost {
    return self.configs[@"reportUrlBase"];
}
- (NSString*)searchReportHost {
    return self.configs[@"reportSearchUrlBase"];
}
@end
