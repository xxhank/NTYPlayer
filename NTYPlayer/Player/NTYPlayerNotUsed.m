//
//  NTYPlayer.m
//  MyTest
//
//  Created by CaiLei on 12/11/14.
//  Copyright (c) 2014 leso. All rights reserved.
//

#import "NTYPlayerNotUsed.h"
@import AVFoundation;
@import MediaPlayer;

#import "NTYObserverUtility.h"
#import "SpacemanBlocks.h"

#ifndef __FILENAME__
#define __FILENAME__          (char*)(strrchr(__FILE__, '/') + 1)
#define NSLogError(fmt,...)   NSLog(@"\033[fg255,0,0;" @"Error: %s:%d %s>" fmt  @"\033;", __FILENAME__, __LINE__, __FUNCTION__,##__VA_ARGS__);
#define NSLogWarngin(fmt,...) NSLog(@"\033[fg255,255,0;" @"Warngin: %s:%d %s>"fmt @"\033;", __FILENAME__, __LINE__, __FUNCTION__,##__VA_ARGS__);
#define NSLogInfo(fmt,...)    NSLog(@"\033[fg127,127,127;" @"Info: %s:%d %s>" fmt @"\033;", __FILENAME__, __LINE__, __FUNCTION__,##__VA_ARGS__);
#endif // ifndef __FILENAME__

static const int kTimeout = 600;

@interface NTYPlayerViewNotUsed : UIView
@property (nonatomic, weak) AVPlayer *player;
@end

@implementation NTYPlayerViewNotUsed
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }

    return self;
}

- (AVPlayer*)player {
    return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player {
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

@end

@interface NTYPlayerNotUsed ()
@property (nonatomic, strong) id                               playerObserver;  // for AVPlayer Periodic Time Observer
@property (nonatomic, strong) NSTimer                         *playerTimer;
@property (nonatomic, strong) AVPlayerItem                    *playerItem;
@property (nonatomic, strong) AVURLAsset                      *asset;
@property (nonatomic, strong) NSMutableArray<NTYObserverType> *observers;
@property (nonatomic, strong) NTYPlayerViewNotUsed            *view;
@property (nonatomic, assign) float                            volume;

@property (nonatomic, assign) CMTime                           tolerance;
@property (nonatomic, assign) NTYPlayerStateNotUsed            playPauseState;
// for check speed
@property (nonatomic, strong) NSDate                          *lastSpeedCheckTime;
@property (nonatomic, assign) long long                        lastBytesTransfered;
// ~ for check speed
@property (nonatomic, assign) SMDelayedBlockHandle             delayedBlockHandle;
@property (nonatomic, strong) dispatch_source_t                timerSource;

@property (nonatomic, strong) MPVolumeView                    *volumeView;
@property (nonatomic, strong) UISlider                        *volumeSlider;

@end

@implementation NTYPlayerNotUsed {}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _resetProperties];
        _observers  = [NSMutableArray array];
        _view       = [[NTYPlayerViewNotUsed alloc] initWithFrame:CGRectZero];
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
        for (id current in _volumeView.subviews) {
            if ([current isKindOfClass:[UISlider class]]) {
                _volumeSlider = (UISlider*)current;
            }
        }

        _volumeView.hidden = YES;
    }

    return self;
}

- (void)dealloc {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player      = nil;
    self.view.player = nil;
    NSLog(@"%@", @"LePlayer Dealloc");
}

#pragma mark - public API
- (void)setVideoUrl:(NSURL*)videoUrl {
    _videoUrl = videoUrl;
    [self _setupWithUrl:_videoUrl];
    self.bSpeedAbleToCalculateRightNow = NO;

    cancel_delayed_block(_delayedBlockHandle);
    @weakify(self);
    _delayedBlockHandle = perform_block_after_delay(MIN(kTimeout, self.timeout), ^{
        @strongify(self);if (!self) {
            return;
        }
        if (self.bIsPlayable) {
            return;
        }

        [self.player pause];
        self->_playPauseState = NNTYPlayerStateNotUsedPaused;
        [self.player replaceCurrentItemWithPlayerItem:nil];
        [self _dealErrorWithMsg:@"time out"];
    });
}

- (void)setBCheckSpeed:(BOOL)bCheckSpeed {
    if (_bCheckSpeed == bCheckSpeed) {
        return;
    }

    _bCheckSpeed = bCheckSpeed;

    if (_bCheckSpeed) {
        [self _startTimer];
    } else {
        if (_timerSource) {
            dispatch_suspend(_timerSource);
        }
    }
}

- (BOOL)play {
    //    if (self.player == nil){
    //        [self _setupWithUrl:self.asset.URL];
    //    }

    if (!self.bIsPlayable) {
        return false;
    }
    NSArray *timeRanges = self.player.currentItem.loadedTimeRanges;
    if (timeRanges.count == 0 && CMTimeGetSeconds([self.playerItem currentTime]) != 0) {
        return false;
    }
    [self.player play];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.state      = NNTYPlayerStateNotUsedPlaying;
    _playPauseState = NNTYPlayerStateNotUsedPlaying;

    return true;
}

- (void)pause {
    //    if (self.player.status != AVPlayerStatusReadyToPlay) {
    //        self.player = nil;
    //    }
    if (!self.bIsPlayable) {
        return;
    }
    [self.player pause];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    self.state      = NNTYPlayerStateNotUsedPaused;
    _playPauseState = NNTYPlayerStateNotUsedPaused;
}

- (void)seekTo:(NSTimeInterval)second {
    if (!self.bIsPlayable) {
        return;
    }
    self.bSpeedAbleToCalculateRightNow = NO;
    self.state                         = NNTYPlayerStateNotUsedBuffering;
    @weakify(self);
    [self.playerItem seekToTime:CMTimeMake(second, 1) toleranceBefore:_tolerance toleranceAfter:_tolerance completionHandler:^(BOOL finished) {
        // Main Thread
        // [GlobalUtils checkMainThread];

        @strongify(self);if (!self) {return;}
        if (!finished) {
            return;
        }

        // 下面这段没用，没有删除掉是因为: 此处为一个例子，可以在block内对RACDisposable调用dispose操作，已达到监听一次状态改变
        /*
           __block RACDisposable *d = [self.playerItem rac_observeKeyPath:@"status"
           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
           observer:self
           block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
           [GlobalUtils checkMainThread];
           if ([value integerValue] == AVPlayerItemStatusReadyToPlay) {
           self.state = self->_playPauseState;
           }
           [d dispose];
           }];
         */
    }];
}

- (void)stop {
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

- (UIView*)playerViewWithFrame:(CGRect)frame {
    self.view.frame = frame;

    return self.view;
}

static const CGFloat kVolumnStep = 0.013;
- (void)increaseVolumn {
    _volumeSlider.value = MIN(_volumeSlider.value + kVolumnStep, 1.f);
}

- (void)decreaseVolumn {
    _volumeSlider.value = MAX(_volumeSlider.value - kVolumnStep, 0.f);
}

- (void)mute {
    _volumeSlider.value = 0.f;
}

- (void)readyVolume {
    _volume = _volumeSlider.value;
}

- (void)getSystemVolumeAdd:(CGFloat)f {
    if (fabs(f) > kVolumnStep) {
        f = f < 0? -kVolumnStep:kVolumnStep;
    }

    _volume = _volume - f;

    NSLog(@"volume: %f", _volume);

    _volumeSlider.value = _volume;
}

#pragma mark - private API
- (void)_resetProperties {
    // 需要notification的property用self.<property>来调用

    _progress = 0.f;
    // _videoUrl        用新值
    // _bCheckSpeed     保持上次
    _state                         = NNTYPlayerStateNotUsedBuffering;
    _duration                      = 0.f;
    self.timePlayed                = 0.f;
    self.timeBuffered              = 0.f;
    _speedByByte                   = 0.f;
    _bSpeedAbleToCalculateRightNow = NO;
    _bIsPlayable                   = NO;
    _error                         = nil;

    _tolerance           = CMTimeMake(10, 1);
    _lastSpeedCheckTime  = nil;
    _lastBytesTransfered = 0l;
}

- (void)_setupWithUrl:(NSURL*)url {
    [self _resetProperties];
    [self _clearObservers];
    cancel_delayed_block(_delayedBlockHandle);
    _delayedBlockHandle = nil;

    if (isEmpty(url)) {
        // 更新bIsPlayable
        self.bIsPlayable = NO;
        [self _dealErrorWithMsg:@"video url empty"];

        return;
    }
    [self.player pause];
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)self.view.layer;
    playerLayer.player = nil;

    self.asset      = [AVURLAsset assetWithURL:url];
    self.state      = NNTYPlayerStateNotUsedBuffering;
    _playPauseState = NNTYPlayerStateNotUsedPlaying;
    @weakify(self);
    [self.asset loadValuesAsynchronouslyForKeys:@[@"duration", @"playable"] completionHandler:^{
        @strongify(self);if (!self) {return;}
        [self loadVideoMetadataFinished];
    }];
} /* _setupWithUrl */


- (void)loadVideoMetadataFinished {
    BOOL             bHasError = NO;
    NSError         *error     = nil;

    AVKeyValueStatus durationStatus = [self.asset statusOfValueForKey:@"duration" error:&error];
    if (durationStatus != AVKeyValueStatusLoaded) {
        NSLogError(@"%@", error);
        bHasError = YES;
        [self _dealErrorWithMsg:@"asset duration : NO"];
    }

    AVKeyValueStatus playableStatus = [self.asset statusOfValueForKey:@"playable" error:&error];

    if (playableStatus != AVKeyValueStatusLoaded) {
        NSLogError(@"%@", error);
        bHasError = YES;
        [self _dealErrorWithMsg:@"asset playable : NO"];
    }

    if (!bHasError) {
        @weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);if (!self) {return;}
            // 更新duration
            self.duration = CMTimeGetSeconds(self.asset.duration);

            self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset];
            self.player = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
            self.view.player = self.player;
            AVPlayerLayer *playerLayer = (AVPlayerLayer*)self.view.layer;
            playerLayer.player = self.player;
            [self _setupObservers];
            if (!self.isNotPlayIng) {
                [self.player play];
            } else {
                NSLogInfo(@"没有播放");
            }
            if (self.progress) {
                [self.playerItem seekToTime:CMTimeMake(self.duration * self.progress, 1) toleranceBefore:_tolerance toleranceAfter:_tolerance completionHandler:^(BOOL finished) {
                    @strongify(self);if (!self) {return;}
                    if (!finished) {
                        return;
                    }
                }];
            }
            if (self.bCheckSpeed) {
                [self _startTimer];
            }
        });
    }
}
- (void)_setupObservers {
    @weakify(self);
    self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                    queue:NULL
                                                               usingBlock:^(CMTime time) {
        // Main Thread
        // [GlobalUtils checkMainThread];

        @strongify(self);if (!self) {return;}
        // 更新timePlayed
        self.timePlayed = CMTimeGetSeconds([self.playerItem currentTime]);
    }];

    NTYNotificationObserver *gd1 = [[NTYNotificationObserver alloc] initWithName:AVPlayerItemDidPlayToEndTimeNotification source:self.playerItem action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        self.state = NNTYPlayerStateNotUsedFinished;
    }];
    [self.observers addObject:gd1];

    NTYNotificationObserver *gd2 = [[NTYNotificationObserver alloc] initWithName:AVPlayerItemFailedToPlayToEndTimeNotification source:self.playerItem action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        [self _dealErrorWithMsg:@"Failed To Play To End"];
    }];
    [self.observers addObject:gd2];

    //*/
    // https://developer.apple.com/library/ios/qa/qa1668/_index.html
    NTYNotificationObserver *gd3 = [[NTYNotificationObserver alloc] initWithName:UIApplicationDidEnterBackgroundNotification source:nil action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        if (!self.bIsPlayable) {
            return;
        }
        self.view.player = nil;
    }];
    [self.observers addObject:gd3];

    NTYNotificationObserver *gd4 = [[NTYNotificationObserver alloc] initWithName:UIApplicationDidBecomeActiveNotification source:nil action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        if (!self.bIsPlayable) {
            return;
        }
        self.view.player = self.player;
    }];
    [self.observers addObject:gd4];
    //*/

    NTYSingleKeyValueObserver *d1 = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"playbackBufferEmpty" target:self.playerItem action:^(id newValue, id oldValue) {
        @strongify(self);if (!self) {return;}
        if ([newValue boolValue]) {
            //NSLog(@"playbackBufferEmpty");
            self.state = NNTYPlayerStateNotUsedBuffering;
            self.bSpeedAbleToCalculateRightNow = NO;
        }
    }];
    [self.observers addObject:d1];

    NTYSingleKeyValueObserver *d2 = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"playbackLikelyToKeepUp" target:self.playerItem action:^(id newValue, id oldValue) {
        @strongify(self);if (!self) {return;}
        if ([newValue boolValue]) {
            //NSLog(@"playbackLikelyToKeepUp");
            self.state = self->_playPauseState;
            // 更新bIsPlayable
            self.bIsPlayable = YES;
        }
    }];
    [self.observers addObject:d2];

    NTYSingleKeyValueObserver *d3 = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"loadedTimeRanges" target:self.playerItem action:^(id newValue, id oldValue) {
        @strongify(self);if (!self) {return;}
        CMTimeRange timeRange = [[newValue lastObject] CMTimeRangeValue];
        if (CMTIME_IS_INDEFINITE(timeRange.start) || CMTIME_IS_INDEFINITE(timeRange.duration)) {
            return;
        }
        double startSeconds = CMTimeGetSeconds(timeRange.start);
        double durationSeconds = CMTimeGetSeconds(timeRange.duration);
        double result = startSeconds + durationSeconds;
        if (isnan(result)) {
            return;
        }
        // 更新timeBuffered
        self.timeBuffered = result;
    }];
    [self.observers addObject:d3];
} /* _setupObservers */

- (void)_clearObservers {
    [self.player removeTimeObserver:self.playerObserver];
    self.playerObserver = nil;

    for (NTYNotificationObserver *d in self.observers) {
        [d dispose];
    }
}

- (void)_startTimer {
    if (_timerSource) {
        dispatch_suspend(_timerSource);
    } else {
        dispatch_queue_t queue = dispatch_get_main_queue();
        _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(_timerSource, dispatch_walltime(DISPATCH_TIME_NOW, 0), 1 * NSEC_PER_SEC, 0);
        @weakify(self);
        dispatch_source_set_event_handler(_timerSource, ^{
            @strongify(self);if (!self) {
                return;
            }
            [self _timerAction];
        });
    }
    dispatch_resume(_timerSource);
}

- (void)_timerAction {
    AVPlayerItemAccessLogEvent *event = [self.player.currentItem.accessLog.events lastObject];
    long long                   byte  = event.numberOfBytesTransferred - self->_lastBytesTransfered;
    //NSLog(@"%lld, %lld", event.numberOfBytesTransferred, self->_lastBytesTransfered);

    static int notModifiedTimes = 0;
    if (byte > 0 && _lastSpeedCheckTime != nil) {
        NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self->_lastSpeedCheckTime];
        // 更新speedByByte
        self.speedByByte = byte / t;
    }
    ;

    if (ABS(byte)) {
        // 当有新event加入events数组时，会重新计numberOfBytesTransferred
        self.bSpeedAbleToCalculateRightNow = YES;
        self->_lastBytesTransfered         = event.numberOfBytesTransferred;
        self->_lastSpeedCheckTime          = [NSDate date];
        notModifiedTimes                   = 0;
    } else {
        notModifiedTimes++;
        if (notModifiedTimes > 5) {
            // 经验数据,大于5次没有改变,认为速度为零
            if (self.bSpeedAbleToCalculateRightNow) {
                self.speedByByte = 0;
            }
        }
    }
}

- (void)_checkPlayableOnTimeout {
    if (self.bIsPlayable) {
        return;
    }

    [self.player pause];
    self->_playPauseState = NNTYPlayerStateNotUsedPaused;
    [self.player replaceCurrentItemWithPlayerItem:nil];
    [self _dealErrorWithMsg:@"time out"];
}

- (void)_dealErrorWithMsg:(NSString*)errMsg {
    self.error = [NSError errorWithDomain:@"PlayerView" code:0 userInfo:@{@"description":errMsg}];
    self.state = NNTYPlayerStateNotUsedError;
}

- (void)controlCurrentAPPVolume:(float)percent {
    [_player setVolume:percent];
}

@end
