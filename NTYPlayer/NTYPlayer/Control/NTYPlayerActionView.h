//
//  NTYPlayerActionView.h
//  NTYPlayer
//
//  Created by wangchao on 2017/9/3.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NTYProgressControl.h"
@import UIKit;

@interface NTYPlayerActionView : UIView
@property (nonatomic, strong) NTYProgressControl *slideProgressView;
@property (nonatomic, assign) BOOL                bLock;
@property (nonatomic, weak) IBOutlet UIButton    *lockButton;
@property (nonatomic, assign) BOOL                bShowTopAndBottomControl;
@property (nonatomic, assign) BOOL                bVideoPlayable;
@property (nonatomic, assign) BOOL                bResolutionMenuShown;
@property (nonatomic, assign) BOOL                bEpisoChooseViewShown;
@property (nonatomic, assign) BOOL                bSliding;

@property (nonatomic, weak) IBOutlet UIView      *topView;
@property (nonatomic, weak) IBOutlet UIView      *bottomView;
@property (nonatomic, weak) IBOutlet UIView      *resolutionMenuView;
@property (nonatomic, weak) IBOutlet UIView      *episoView;

@property (nonatomic, strong) NSTimer            *barHideTimer;
@property (nonatomic, weak) IBOutlet UIButton    *centerPlayButton;
@end
