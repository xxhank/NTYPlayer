//
//  LEVideoSlideProgressControl.h
//  testSliderProgressView
//
//  Created by CaiLei on 4/14/14.
//  Copyright (c) 2014 Le123. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTYProgressControl : UIControl

@property (nonatomic, strong) UIColor       *minColor;
@property (nonatomic, strong) UIColor       *midColor;
@property (nonatomic, strong) UIColor       *maxColor;

@property (nonatomic,assign) NSTimeInterval  minimumValue;
@property (nonatomic, assign) NSTimeInterval maximumValue;

@property (nonatomic, assign) CGFloat        value1; /// 播放进度
@property (nonatomic, assign) CGFloat        value2; /// 缓冲进度

@property (nonatomic, strong) UIImage       *slideImage;
@property (nonatomic, strong) UIView        *slideInfoView;

- (void)showPopAnimated:(BOOL)animated;
- (void)hidePopAnimated:(BOOL)animated;
@end
