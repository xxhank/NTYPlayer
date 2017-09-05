//
//  AppSettings.m
//  Fibra
//
//  Created by wangchao9 on 2017/6/22.
//  Copyright © 2017年 wangchao9. All rights reserved.
//

#import "AppSettings.h"

@protocol SASAppConfigUrlItem <NSObject>
@end

@interface SASAppConfigUrlItem : NSObject
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly) NSString *name;
@end

@interface SASAppConfigForQAManager : NSObject
@property (nonatomic, strong, readonly) SASAppConfigUrlItem          *currentUrlItem;
@property (nonatomic, strong, readonly) NSArray<SASAppConfigUrlItem> *urlItemsArray;
@property (nonatomic, strong, readonly) NSArray<SASAppConfigUrlItem> *cityItemsArray;
- (void)changeUrlToItemAtIndex:(NSInteger)index;
///设置自定义url地址
- (void)setUrlForCustomUrlItem:(NSString*)urlStr;
@end

@implementation AppSettings {
    NSArray<NSDictionary*>*_urls;
    NSArray<NSDictionary*>*_cities;
}

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AppSettings    *settings;
    dispatch_once(&onceToken, ^{
        settings = [[self class] new];
    });
    return settings;
}

+ (NSString*)curentHost {
    return [[[self class] shared] curentHost];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _urls = @[@{@"name":@"线上环境https",@"url":@"https://www.shandianshipin.cn/"},
                  @{@"name":@"线上环境http",@"url":@"http://www.shandianshipin.cn/"},
                  @{@"name":@"测试环境http",@"url":@"http://106.120.179.78/"},
                  @{@"name":@"测试环境https",@"url":@"https://106.120.179.78/"},
                  @{@"name":@"自定义      ",@"url":@"http://106.120.179.78/"}
        ];

        _cities = @[@{@"name":@"一线：北京市",@"value":@"CN_1_5_1"},
                    @{@"name":@"二线：青岛市",@"value":@"CN_15_187_2"},
                    @{@"name":@"三线：济宁市",@"value":@"CN_15_193_3"},
                    @{@"name":@"四线：日照市",@"value":@"CN_15_196_4"},
                    @{@"name":@"五线：北海市",@"value":@"CN_20_271_5"},
        ];
    }
    return self;
}

static NSString* const kQASetURLIndex = @"QASetURLIndex";
- (NSString*)curentHost {
    NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
    NSInteger      index    = [defaults integerForKey:kQASetURLIndex];
    if (index > _urls.count - 1) {
        index = 0;
    }
    return _urls[index][@"url"];
}

#pragma mark - property
- (NSString*)token {return nil;}
- (NSString*)uid {return nil;}
@end
