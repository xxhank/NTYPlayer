//
//  NTYPlayer.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NTYPlayer.h"
@import UIKit;
@import AVFoundation;
@import MediaPlayer;
#import "NTYTasksExecutor.h"
#import "NTYKeyValueObserver.h"

@interface NTYPlayerView : UIView
@property (nonatomic, weak) AVPlayer *player;
@end

@implementation NTYPlayerView
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


@interface AVURLAsset (NTYSupportCancel)<NTYSupportCancel>
@end

@implementation AVURLAsset (NTYSupportCancel)
- (void)cancel {[self cancelLoading];}
@end

NSString*NTYPlayerStateStringify(NTYPlayerState state) {
    switch (state) {
    case NTYPlayerStateUnknown: return @"NTYPlayerStateUnknown";
    case NTYPlayerStatePreparing: return @"NTYPlayerStatePreparing";
    case NTYPlayerStatePlaying: return @"NTYPlayerStatePlaying";
    case NTYPlayerStatePaused: return @"NTYPlayerStatePaused";
    case NTYPlayerStateFailed: return @"NTYPlayerStateFailed";
    case NTYPlayerStateFinished: return @"NTYPlayerStateFinished";
    }
}

@interface NTYPlayer ()
@property (nonatomic, strong) NSArray<NSURL*>    *urls;
@property (nonatomic, strong) NSArray<NSNumber*> *durations;
@property (nonatomic, strong) NSDictionary       *headers;
@property (nonatomic, assign) NSTimeInterval      position;          ///< 开始播放的位置,0表示从头开始播放

#pragma mark - config
@property (nonatomic, assign) CMTime tolerance; /// seek的精度

#pragma mark - PlayerView
@property (nonatomic, strong) NTYPlayerView *render;

#pragma mark - VolumnView
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UISlider     *volumeSlider;

#pragma mark - AVPlayer
@property (nonatomic, strong) AVPlayer                    *player;
@property (nonatomic, strong) AVPlayerItem                *playingItem;
@property (nonatomic, strong) AVURLAsset                  *playingAsset;
@property (nonatomic, strong) AVPlayerItem                *cachingItem;

@property (nonatomic, strong) NSMutableArray<AVURLAsset*> *assets; ///< just for cache

#pragma mark - Tasks
@property (nonatomic, strong) NTYTasksExecutor                *executor;
@property (nonatomic, strong) NSMutableArray<NTYObserverType> *observers;
@property (nonatomic, strong) id                               periodicTimeObserver;

#pragma mark - Total
@property (nonatomic, assign) NTYPlayerState state;
@property (nonatomic, strong) NSError       *error;
@property (nonatomic, assign) NSTimeInterval played;
@property (nonatomic, assign) NSTimeInterval duration;


#pragma mark - Segment
/// 当前播放的片段索引
@property (nonatomic, assign) NSUInteger                 segment_currentIndex;
/// 当前偏移量在片段中的位置
@property (nonatomic, assign) NSTimeInterval             segment_position;
@property (nonatomic, strong) NSMutableArray<NSNumber*> *segment_previousTotalDurations;       ///< 指定片段前面的的总长度, 用于计算当前播放位置
@end

@implementation NTYPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        _assets    = [NSMutableArray arrayWithCapacity:0x4];
        _tolerance = CMTimeMake(10, 1);
        _render    = [[NTYPlayerView alloc] initWithFrame:RECT(0, 0, 320, 180)];
        _observers = [NSMutableArray arrayWithCapacity:0x4];
        [self buildVolumeView];
    }
    return self;
}

- (void)dealloc {
    NSLogInfo(@"");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.executor cancel];
    if (self.periodicTimeObserver) {
        [self.player removeTimeObserver:self.periodicTimeObserver];
    }
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player        = nil;
    self.render.player = nil;
}

#pragma mark - Render
- (UIView*)contentView {return self.render;}
#pragma mark - Interface
- (void)playWithURLs:(NSArray<NSString*>*)urls
            position:(NSTimeInterval)position
           durations:(NSArray<NSNumber*>*)durations
             headers:(NSDictionary*)headers {
    NTYAssert(self.state != NTYPlayerStatePlaying, @"Invalid state %@", NTYPlayerStateStringify(self.state))

    [UIApplication sharedApplication].idleTimerDisabled = YES;

    self.urls = [urls nty_map:^id (NSString *obj, NSUInteger idx) {
        return NTYURL(obj);
    }];
    self.headers  = headers;
    self.position = position;

    self.state = NTYPlayerStatePreparing;

    /// 想办法重新获取每一段视频的时长
    if (self.urls.count != durations.count) {
        NSDictionary *options = @{
            @"AVURLAssetHTTPHeaderFieldsKey":headers?:@{},
            //AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)
        };

        @weakify(self);
        self.executor = [[NTYTasksExecutor alloc] init];
        for (NSURL *url  in self.urls) {
            [self.executor addTask:^id < NTYSupportCancel > (NSUInteger index, TaskBlockCompltion _Nonnull completion) {
                @strongify(self);
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:options];
                [self.assets addObject:asset];
                NSLogInfo(@"segment#%@ fetching duration", @(index));
                @weakify(asset);
                [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
                    @strongify(self, asset);
                    NSError *error = nil;
                    AVKeyValueStatus status = [asset statusOfValueForKey:@"duration" error:&error];
                    switch (status) {
                    case AVKeyValueStatusLoaded:
                        NSLogInfo(@"segment#%@ loaded", @(index));
                        completion(index, [NTYResult resultWithValue:@(CMTimeGetSeconds(asset.duration))]);
                        break;
                    case AVKeyValueStatusFailed:
                        NSLogError(@"segment#%@ failed.%@", @(index), error);
                        completion(index, [NTYResult resultWithError:error?:NTYError(0, @"Get Duration Failed")]);
                        break;
                    case AVKeyValueStatusCancelled:
                        NSLogWarn(@"segment#%@ cancelled", @(index));
                        completion(index, [NTYResult resultWithError:error?:NTYError(0, @"Get Duration Cancelled")]);
                        break;
                    case AVKeyValueStatusUnknown:
                        NSLogWarn(@"segment#%@ unknown", @(index));
                        break;
                    case AVKeyValueStatusLoading:
                        NSLogWarn(@"segment#%@ loading", @(index));
                        break;
                    }
                }];

                return asset;
            }];
        }

        [self.executor run:^(NTYResult < NSArray* > *_Nonnull result) {
            @strongify(self);
            self.durations = [result.value nty_filter:^BOOL (NSNumber *obj, NSUInteger idx) {
                return [NSNumber has:obj];
            }];

            [self.assets removeAllObjects];

            if (self.durations.count != self.urls.count) {
                self.state = NTYPlayerStateFailed;
                self.error = NTYError(0, @"Get Duration failed");
                if (self.stateUpdated) {
                    self.stateUpdated(self.state);
                } else {
                    NSLogError(@"player failed. %@", self.error);
                }
            } else {
                [self processDurations];
                if (self.durationUpdated) {
                    self.durationUpdated(self.duration);
                } else {
                    NSLogInfo(@"duration updated. %@", @(self.duration));
                }

                NSArray<NSNumber*> *values = [self segment_locate:position];
                self.segment_currentIndex = [values[0] unsignedIntegerValue];
                self.segment_position = [values[1] doubleValue];
                [self playSegment];
            }
        }];
    } else {
        [Dispatch after:1 execute:^{
            self.durations = durations;
            [self processDurations];
            if (self.durationUpdated) {
                self.durationUpdated(self.duration);
            } else {
                NSLogInfo(@"duration updated. %@", @(self.duration));
            }

            NSArray<NSNumber*> *values = [self segment_locate:position];
            self.segment_currentIndex = [values[0] unsignedIntegerValue];
            self.segment_position = [values[1] doubleValue];
            [self playSegment];
        }];
    }
}

- (void)stop {
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

- (void)pause {
    self.state = NTYPlayerStatePaused;
    [self.player pause];
}

- (void)resume {
    self.state = NTYPlayerStatePlaying;
    [self.player play];
}

- (void)seek:(NSTimeInterval)position {
    NSLogInfo(@"%f", position);
    NSArray<NSNumber*> *values               = [self segment_locate:position];
    NSUInteger          segment_currentIndex = [values[0] unsignedIntegerValue];
    CGFloat             segment_position     = [values[1] doubleValue];

    /// 同一段流seek
    if (segment_currentIndex == self.segment_currentIndex) {
        NSLogInfo(@"player seek in same segments:%@.", values);
        [self.playingItem seekToTime:CMTimeMakeWithSeconds(segment_position, NSEC_PER_SEC)
                     toleranceBefore:self.tolerance
                      toleranceAfter:self.tolerance
                   completionHandler:^(BOOL finished) {
            NSLogInfo(@"%@", @(finished));
        }];
    } else {
        NSLogInfo(@"player seek new segment: %@.", values);
        self.segment_currentIndex = segment_currentIndex;
        self.segment_position     = segment_position;
        [self playSegment];
    }
}


#pragma mark -
- (void)processDurations {
    self.segment_previousTotalDurations = [NSMutableArray arrayWithCapacity:self.urls.count];
    NSTimeInterval totalDuration = 0;
    for (NSNumber *value in self.durations) {
        NSTimeInterval duration = value.doubleValue;
        [self.segment_previousTotalDurations addObject:@(totalDuration)];
        totalDuration += duration;
    }
    self.duration = totalDuration;
}
- (void)playSegment {
    NSURL        *url     = self.urls[self.segment_currentIndex];
    NSDictionary *options = @{
        @"AVURLAssetHTTPHeaderFieldsKey":self.headers?:@{},
    };
    self.playingAsset = [AVURLAsset URLAssetWithURL:url options:options];

    @weakify(self);
    [self.playingAsset loadValuesAsynchronouslyForKeys:@[@"duration", @"playable"] completionHandler:^{
        @strongify(self);if (!self) {return;}
        [self loadVideoMetadataFinished:self.playingAsset];
    }];
}

- (void)loadVideoMetadataFinished:(AVURLAsset*)asset {
    NSError         *error          = nil;
    AVKeyValueStatus durationStatus = [asset statusOfValueForKey:@"duration" error:&error];
    if (durationStatus != AVKeyValueStatusLoaded) {
        NSLogError(@"%@", error);
        self.state = NTYPlayerStateFailed;
        self.error = NTYError(NTYPlayerErrorGetDurationFailed, @"Get Duration Failed");
        if (self.stateUpdated) {
            self.stateUpdated(self.state);
        } else {
            NSLogError(@"player %@ %@", NTYPlayerStateStringify(self.state), self.error);
        }
        return;
    }

    AVKeyValueStatus playableStatus = [asset statusOfValueForKey:@"playable" error:&error];
    if (playableStatus != AVKeyValueStatusLoaded) {
        NSLogError(@"%@", error);
        self.state = NTYPlayerStateFailed;
        self.error = NTYError(NTYPlayerErrorGetDurationFailed, @"Get Duration Failed");
        if (self.stateUpdated) {
            self.stateUpdated(self.state);
        } else {
            NSLogError(@"player %@ %@", NTYPlayerStateStringify(self.state), self.error);
        }
        return;
    }
    if (self.cachingItem) {
        self.playingItem = self.cachingItem;
        self.cachingItem = nil;
    } else {
        self.playingItem = [[AVPlayerItem alloc] initWithAsset:asset];
    }
    if (!self.player) {
        self.player        = [[AVPlayer alloc] initWithPlayerItem:self.playingItem];
        self.render.player = self.player;
    } else {
        [self.player replaceCurrentItemWithPlayerItem:self.playingItem];
    }

    [self setupObservers];

    self.state = NTYPlayerStatePlaying;
    [self.player play];

    if (self.segment_position > 0) {
        [self.playingItem seekToTime:CMTimeMake(self.segment_position, 1)
                     toleranceBefore:self.tolerance
                      toleranceAfter:self.tolerance
                   completionHandler:^(BOOL finished) {
            NSLogInfo(@"%@", @(finished));
        }];
    }
}

#pragma mark - segment
NSArray<NSNumber*>*findIndexAndOffsetForPositonInDurations(NSTimeInterval position, NSArray<NSNumber*>*durations) {
    NSUInteger     segment_currentIndex = 0;
    NSTimeInterval segment_position     = 0;

    NSTimeInterval total         = 0;
    NSTimeInterval durationValue = 0;
    NSUInteger     segmentIndex  = 0;
    BOOL           match         = NO;
    for (NSNumber *duration in durations) {
        durationValue = [duration doubleValue];
        if (position >= total && position < total + durationValue) {
            segment_currentIndex = segmentIndex;
            segment_position     = position - total;
            match                = YES;
            break;
        }
        segmentIndex++;
        total += durationValue;
    }

    if (!match && position > total) {
        segment_currentIndex = durations.count - 1;
        segment_position     = durationValue;
    }

    NSArray<NSNumber*>*result = @[@(segment_currentIndex),@(segment_position)];
    return result;
}

- (NSArray<NSNumber*>*)segment_locate:(NSTimeInterval)position {
    NSArray<NSNumber*>*result = findIndexAndOffsetForPositonInDurations(position, self.durations);
    NSLogInfo(@"player %@", result);
    return result;
}

#pragma mark - volume
- (void)buildVolumeView {
    _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    for (id current in _volumeView.subviews) {
        if ([current isKindOfClass:[UISlider class]]) {
            _volumeSlider = (UISlider*)current;
        }
    }
    _volumeView.hidden = YES;
}

- (void)setVolume:(CGFloat)volume {
    self.volumeSlider.value = MIN(MAX(0,volume), 1);
}
- (CGFloat)volume {
    return self.volumeSlider.value;
}

#pragma mark - Player State
- (void)setupObservers {
    CMTime interval = CMTimeMakeWithSeconds(1, NSEC_PER_SEC);
    if (self.periodicTimeObserver) {
        [self.player removeTimeObserver:self.periodicTimeObserver];
    }
    @weakify(self);
    self.periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:interval
                                                                          queue:dispatch_get_main_queue()
                                                                     usingBlock:^(CMTime time) {
        @strongify(self);
        NSTimeInterval seconds = CMTimeGetSeconds(time);
        self.played = seconds + self.segment_previousTotalDurations[self.segment_currentIndex].doubleValue;
        if (self.playedUpdated) {
            self.playedUpdated(self.played);
        } else {
            NSLogInfo(@"player segment#%@ played  %@",@(self.segment_currentIndex), @(seconds));
        }
    }];

    [self.observers removeAllObjects];

    NTYNotificationObserver *playFinishedObserver = [[NTYNotificationObserver alloc] initWithName:AVPlayerItemDidPlayToEndTimeNotification source:self.playingItem action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        self.state = NTYPlayerStateFinished;
        if (self.segment_currentIndex < self.urls.count - 1) {
            self.segment_currentIndex += 1;
            self.segment_position = 0;
            [self playSegment];
        } else {
            /// 最后一段播放结束
            if (self.stateUpdated) {
                self.stateUpdated(self.state);
            } else {
                NSLogInfo(@"player play finished");
            }
        }
    }];
    [self.observers addObject:playFinishedObserver];

    NTYNotificationObserver *playFailedObserver = [[NTYNotificationObserver alloc] initWithName:AVPlayerItemFailedToPlayToEndTimeNotification source:self.playingItem action:^(NSNotification *notification) {
        @strongify(self);if (!self) {return;}
        // [self _dealErrorWithMsg:@"Failed To Play To End"];
        self.state = NTYPlayerStateFailed;
        self.error = self.playingItem.error;
        NSLogError(@"player segment#%zd play failed %@ %@", self.segment_currentIndex, self.player.error, self.playingItem.error);

        if (self.stateUpdated) {
            self.stateUpdated(self.state);
        } else {
        }
    }];
    [self.observers addObject:playFailedObserver];

   #if 0 /// 播放器不应该关心是否切入到后台
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
   #endif // if 0

    NTYSingleKeyValueObserver *playerNeedBufferObserver = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"playbackBufferEmpty" target:self.playingItem action:^(id newValue, id oldValue) {
        @strongify(self);if (!self) {return;}
        if ([newValue boolValue]) {
            self.bufferState = NTYPlayerBufferStateBuffering;
            if (self.bufferStateUpdated) {
                self.bufferStateUpdated(self.bufferState);
            } else {
                NSLogInfo(@"player start buffer");
            }
        }
    }];
    [self.observers addObject:playerNeedBufferObserver];

    NTYSingleKeyValueObserver *playerGotEnoughDataObserver = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"playbackLikelyToKeepUp" target:self.playingItem action:^(id newValue, id oldValue) {
        @strongify(self);if (!self) {return;}
        if ([newValue boolValue]) {
            self.bufferState = NTYPlayerBufferStateFinished;
            if (self.bufferStateUpdated) {
                self.bufferStateUpdated(self.bufferState);
            } else {
                NSLogInfo(@"player end buffer");
            }
            self.bufferState = NTYPlayerBufferStateWaiting;
        }
    }];
    [self.observers addObject:playerGotEnoughDataObserver];

    NTYSingleKeyValueObserver *playerBufferedSizeObserver = [[NTYSingleKeyValueObserver alloc] initWithKeyPath:@"loadedTimeRanges" target:self.playingItem action:^(id newValue, id oldValue) {
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
    [self.observers addObject:playerBufferedSizeObserver];
}
@end
