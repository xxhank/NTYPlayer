//
//  NTYTimeConvert.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/3.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NTYTimeConvert.h"

@implementation NTYTimeConvert
+ (NSString*)HHMMSSTextFromSeconds:(NSTimeInterval)totalDuration {
    const NSUInteger SecondsPerHour   = 60 * 60;
    const NSUInteger SecondsPerMinute = 60;

    NSUInteger       hour    = totalDuration / SecondsPerHour;
    NSUInteger       left    = totalDuration - hour * SecondsPerHour;
    NSUInteger       minutes = left / SecondsPerMinute;
    NSUInteger       seconds = left - minutes * SecondsPerMinute;
    if (hour > 0) {
        return STRING(@"%02zd:%02zd:%02zd", hour, minutes, seconds);
    } else {
        return STRING(@"%02zd:%02zd", minutes, seconds);
    }
}
@end
