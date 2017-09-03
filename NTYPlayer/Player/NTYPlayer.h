//
//  NTYPlayer.h
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, NTYPlayerState) {
    NTYPlayerStateUnknown,
    NTYPlayerStatePreparing,///< 获取时长
    NTYPlayerStatePlaying,
    NTYPlayerStatePaused,
    NTYPlayerStateFailed
};
NSString*NTYPlayerStateStringify(NTYPlayerState state);


typedef NS_ENUM (NSUInteger, NTYPlayerError) {
    NTYPlayerErrorGetDurationFailed,
};

typedef void (^NTYPlayerDurationUpdated)(NSTimeInterval totalDuration);
typedef void (^NTYPlayerStateUpdated)(NTYPlayerState state);
typedef void (^NTYPlayerPlayedUpdated)(NSTimeInterval played);

@interface NTYPlayer : NSObject

@property (nonatomic, assign, readonly) NTYPlayerState state;
@property (nonatomic, assign, readonly) NSTimeInterval played;
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, readonly) UIView                *contentView;


/**
 *  音量,取值范围[0,1]
 */
@property (nonatomic, assign) CGFloat volume;

/**
 *  播放器错误
 */
@property (nonatomic, strong, readonly, nullable) NSError*error;

- (void)playWithURLs:(NSArray<NSString*>*)urls
            position:(NSTimeInterval)position
           durations:(nullable NSArray<NSNumber*>*)durations
             headers:(nullable NSDictionary*)headers;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)seek:(NSTimeInterval)position;

@property (nonatomic, copy) NTYPlayerDurationUpdated durationUpdated;
@property (nonatomic, copy) NTYPlayerStateUpdated    stateUpdated;
@property (nonatomic, copy) NTYPlayerPlayedUpdated   playedUpdated;
@end

NS_ASSUME_NONNULL_END
