//
//  NTYObserverUtility.h
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NTYObserver <NSObject>
- (void)dispose;
@end
typedef id<NTYObserver> NTYObserverType;

typedef void (^NTYNotificationAction)(NSNotification *notification);
@interface NTYNotificationObserver : NSObject<NTYObserver>
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSNotificationName)name source:(nullable id)source action:(NTYNotificationAction)block;
@end


typedef void (^NTYKeyValueAction)(id newValue, id oldValue);
@interface NTYSingleKeyValueObserver : NSObject<NTYObserver>
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithKeyPath:(nonnull NSString*)keyPath target:(id)target action:(NTYKeyValueAction)block;
@end
NS_ASSUME_NONNULL_END
