//
//  NTYPlayerActionView.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/3.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NTYPlayerActionView.h"

@interface NTYPlayerActionView ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *hpan;
@property (nonatomic, strong) UIPanGestureRecognizer *vpan;
@end
@implementation NTYPlayerActionView

- (void)setup {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tap];

    UIPanGestureRecognizer *hpan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(hpanAction:)];
    [self addGestureRecognizer:hpan];
    hpan.delegate = self;
    self.hpan     = hpan;
    UIPanGestureRecognizer *vpan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(vpanAction:)];
    [self addGestureRecognizer:vpan];
    vpan.delegate = self;
    self.vpan     = vpan;
}

#pragma mark - UIGestureRecognizerDelegate
- (void)tapAction:(UITapGestureRecognizer*)recognizer {
    if (!self.bVideoPlayable) {
        return;
    }

    if (self->_bResolutionMenuShown) {
        [self _hideResolutionMenu];
        if (self.bVideoPlayable) {
            [self _showBottomWithAnimate];
            [self _showTopWithAnimate];
            [self _resetHideTimer];
        }

        return;
    }

    if (self->_bEpisoChooseViewShown) {
        [self _hideEpisoView];
        if (self.bVideoPlayable) {
            [self _showBottomWithAnimate];
            [self _showTopWithAnimate];
            [self _resetHideTimer];
        }

        return;
    }

    if (self.bShowTopAndBottomControl) {
        [self _hideTopWithAnimate];
        [self _hideBottomWithAnimate];
    } else {
        if (self->_bLock) {
            [UIView animateWithDuration:0.2
                             animations:^{
                self.lockButton.alpha = 1.f;
            }];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        } else {
            [self _showTopWithAnimate];
            [self _showBottomWithAnimate];
        }
        [self _resetHideTimer];
    }
    self.bShowTopAndBottomControl = !self.bShowTopAndBottomControl;
} // tapAction

- (void)hpanAction:(UIPanGestureRecognizer*)recognizer {
    //NSLogInfo(@"horizontal");
    if (self->_bLock) {
        return;
    }

    if (!self.bVideoPlayable) {
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self->_bSliding = YES;
        [self _showTopWithAnimate];
        [self _showBottomWithAnimate];
        [self.slideProgressView showPopAnimated:YES];
    }

    if (recognizer.state == UIGestureRecognizerStateChanged) {
        self->_bSliding = YES;
        CGPoint translation = [recognizer translationInView:self];
        [recognizer setTranslation:CGPointMake(0, 0) inView:self];
        self.slideProgressView.value1 += translation.x / 2000;
    }

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.slideProgressView hidePopAnimated:YES];
        [self _resetHideTimer];

        NSTimeInterval seekTime = self.slideProgressView.value1;
        self->_bSliding = NO;
        #warning "play"
   #if 0
        self.playerView.userWantSeekToTime = seekTime;
        if (self.playerView.userWantSeekToTime >= self.playerView.duration) {
            [self report12];
            if (self.curPlayIndex >= [self.episodeArray count] - 1) {
                // 已经播放到最后一条, 最后一条history，为重播
                self.slideProgressView.value1 = 0.f;
                [self backAction:nil];
            } else {
                [self episo:nil selectAtIndex:self.curPlayIndex + 1 external:NO isUpdateSite:NO];
            }
        } else {
            [self _doSeekAfterDelay];
            [self _resetHideTimer];
        }
   #endif // if 0
    }
} // hpanAction

- (void)vpanAction:(UIPanGestureRecognizer*)recognizer {
    if (self->_bLock) {
        return;
    }

    if (!self.bVideoPlayable) {
        return;
    }
    static CGFloat transY = 0.0f;
    switch (recognizer.state) {
    case UIGestureRecognizerStateBegan:
        transY = 0.0f;
        break;

    case UIGestureRecognizerStateChanged: {
        CGPoint translation = [recognizer translationInView:recognizer.view];

        float   change = (transY - translation.y) / (recognizer.view.frame.size.height / 2);
        transY = translation.y;
        NSLogInfo(@"change = %f",change);
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            #warning "ajust volume"
            // [self.playerView getSystemVolumeAdd:change];
        }
        break;
    }

    case UIGestureRecognizerStateEnded:

    default:
        break;
    } // switch
}

#pragma mark -
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer*)panGestureRecognizer {
    CGPoint velocity = [panGestureRecognizer velocityInView:self];
    if (panGestureRecognizer == self->_hpan) {
        return fabs(velocity.x) >= fabs(velocity.y);
    }

    if (panGestureRecognizer == self->_vpan) {
        return fabs(velocity.x) < fabs(velocity.y);
    }

    return YES;
}

#pragma mark -
- (void)_hideResolutionMenu {
    if (!self.bVideoPlayable) {
        [self _resetHideTimer];
    }
    self->_bResolutionMenuShown = NO;
    [UIView animateWithDuration:0.2
                     animations:^{
        CGRect frame = self.resolutionMenuView.frame;
        frame.origin.x = self.bounds.size.width;
        self.resolutionMenuView.frame = frame;
    }];
}

- (void)_showTopWithAnimate {
    if (!self->_bLock) {
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            self.topView.alpha = 1.f;
        } completion:^(BOOL finished) {}];
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)_hideTopWithAnimate {
    [UIView animateWithDuration:0.5
                     animations:^{
        self.topView.alpha = 0.f;
   #if 0
        self.pushComplainBtn.hidden = YES;
   #endif // if 0
    }];

    #warning ""
   #if 0
    if (!self.isHalfScreen && selfDismiss == NO) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
   #endif // if 0
    [self _hideEpisoView];
}

- (void)_showBottomWithAnimate {
    if (self->_bEpisoChooseViewShown) {
        return;
    }
    [UIView animateWithDuration:0.2
                     animations:^{
        self->_bEpisoChooseViewShown = NO;
        CGRect frame = self.episoView.frame;
        frame.origin.x = self.bounds.size.width;
        self.episoView.frame = frame;
        if (!self->_bLock) {
            self.bottomView.alpha = 1.f;
            self.centerPlayButton.alpha = 1.f;
        }
        self.lockButton.alpha = 1.f;
    }];
}

- (void)_hideBottomWithAnimate {
    if (self->_bResolutionMenuShown) {
        [self _hideResolutionMenu];
    }
    [UIView animateWithDuration:0.5
                     animations:^{
        self.bottomView.alpha = 0.f;
        self.centerPlayButton.alpha = 0.0f;
        self.lockButton.alpha = 0.f;
    }];
    //隐藏切换分辨率提示Label
    // self.resolutionChangeStateLabel.hidden = YES;
}

- (void)_resetHideTimer {
    [self.barHideTimer invalidate];
    self.barHideTimer = [NSTimer scheduledTimerWithTimeInterval:5.f
                                                         target:self
                                                       selector:@selector(_resetTimerAction)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)_hideEpisoView {
    if (!self.bVideoPlayable) {
        [self _resetHideTimer];
    }

    [UIView animateWithDuration:0.2
                     animations:^{
        CGRect frame = self.episoView.frame;
        frame.origin.x = self.bounds.size.width;
        self.episoView.frame = frame;
    }];
    // self.episodesVC.episodesPlatView.isShowing = NO;
    self->_bEpisoChooseViewShown = NO;
}

- (void)_resetTimerAction {
    if (!self.bVideoPlayable) {
        return;
    }

    self.bShowTopAndBottomControl = NO;
    [self _hideTopWithAnimate];
    [self _hideBottomWithAnimate];
}
@end
