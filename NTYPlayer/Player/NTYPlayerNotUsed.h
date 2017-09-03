//
//  NTYPlayer.h
//  MyTest
//
//  Created by CaiLei on 12/11/14.
//  Copyright (c) 2014 leso. All rights reserved.
//

@import Foundation;
@import UIKit;
@import AVFoundation;

typedef NS_ENUM (NSUInteger, NTYPlayerStateNotUsed) {
    NNTYPlayerStateNotUsedBuffering,
    NNTYPlayerStateNotUsedPlaying,
    NNTYPlayerStateNotUsedPaused,
    NNTYPlayerStateNotUsedFinished,
    NNTYPlayerStateNotUsedError = 99
};

@interface NTYPlayerNotUsed : NSObject

#pragma mark - in
@property (nonatomic, assign) CGFloat progress; // 最好在videoUrl之前设置progress才能起作用
@property (nonatomic, strong) NSURL  *videoUrl;
@property (nonatomic, assign) BOOL    bCheckSpeed;
@property (nonatomic, assign) int     timeout;

#pragma mark - out
@property (nonatomic, assign) NTYPlayerStateNotUsed state;
@property (nonatomic, assign) CGFloat        duration;
@property (nonatomic, assign) CGFloat        timePlayed;
@property (nonatomic, assign) CGFloat        timeBuffered;
@property (nonatomic, assign) CGFloat        speedByByte;

/**
 *  在一下情况的初始阶段，我们无法测速:
 *  1, 视频第一次加载
 *  2, 拖动进度到没有缓冲的部分
 *  3, 从后台切换到前台
 */
@property (nonatomic, assign) BOOL      bSpeedAbleToCalculateRightNow;
@property (nonatomic, assign) BOOL      bIsPlayable;
@property (nonatomic, assign) BOOL      isNotPlayIng;
@property (nonatomic, strong) NSError  *error;

@property (nonatomic, strong) AVPlayer *player;
#pragma mark - public API
- (BOOL)play;
- (void)pause;
- (void)seekTo:(NSTimeInterval)second;
- (void)stop;

- (UIView*)playerViewWithFrame:(CGRect)frame;

// 音量控制
- (void)increaseVolumn;
- (void)decreaseVolumn;
- (void)mute;
- (void)getSystemVolumeAdd:(CGFloat)f;
- (void)readyVolume;

// 降低50%音量
- (void)controlCurrentAPPVolume:(float)percent;

@end
