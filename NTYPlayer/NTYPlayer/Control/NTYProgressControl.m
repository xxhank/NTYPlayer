//
//  LEVideoSlideProgressControl.m
//  testSliderProgressView
//
//  Created by CaiLei on 4/14/14.
//  Copyright (c) 2014 Le123. All rights reserved.
//

#import "NTYProgressControl.h"
#import "NTYTimeConvert.h"
#import "NTYProgressPopover.h"

static const CGFloat kTimeLablePadding = 10;
static const CGFloat kLineHeight       = 1.f;
static const CGFloat kHitTestScale     = 2.0f;

@interface NTYProgressControl ()
@property (nonatomic, strong) UILabel            *playedTimeLabel;
@property (nonatomic, strong) UILabel            *durationLabel;
@property (nonatomic, assign) CGFloat             timeLableWidth;
@property (nonatomic, strong) NTYProgressPopover *popView;
@end

@implementation NTYProgressControl
- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setup];
    }
    return self;
}

- (void)setMaximumValue:(NSTimeInterval)maxTime {
    _maximumValue = maxTime;
    if (_maximumValue > 3600) {
        self.timeLableWidth = 57;
    } else {
        self.timeLableWidth = 46;
    }
}

- (void)setValue2:(CGFloat)progressPoint {
    _value2 = MAX(MIN(progressPoint, 1), 0);
    [self setNeedsDisplay];
}

- (void)setValue1:(CGFloat)slidePoint {
    _value1 = MAX(MIN(slidePoint, 1), 0);
    [self setNeedsDisplay];
}


- (void)_setup {
    self.clipsToBounds = NO;

    self.backgroundColor = [UIColor clearColor];
    self.minColor        = COLOR_HEX(0x3599F8);
    self.midColor        = COLOR_HEX(0xa0a0a0);
    self.maxColor        = COLOR_HEX(0xffffff);
    self.slideImage      = [UIImage imageNamed:@"播放器进度条-圆圈"];

    self.popView       = [[NTYProgressPopover alloc] init];
    self.popView.alpha = 0.f;
    [self addSubview:self.popView];

    self.playedTimeLabel = [[[UILabel alloc] initWithFrame:CGRectZero]
                            sas_decorate:^(__kindof UILabel*_Nonnull label) {
        label.textAlignment = NSTextAlignmentRight;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.f];
        label.textColor = [UIColor whiteColor];
        [self addSubview:label];
    }];


    self.durationLabel = [[[UILabel alloc] initWithFrame:CGRectZero]
                          sas_decorate:^(__kindof UILabel*_Nonnull label) {
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12.f];
        label.textColor = [UIColor whiteColor];
        [self addSubview:label];
    }];

    [self setMaximumValue:_maximumValue];
}

- (void)drawRect:(CGRect)rect {
    NSString *playedText   = [NTYTimeConvert HHMMSSTextFromSeconds:self.maximumValue * self.value1];
    NSString *durationText = [NTYTimeConvert HHMMSSTextFromSeconds:self.maximumValue];

    CGFloat   labelWidth = self.timeLableWidth - kTimeLablePadding;

    self.playedTimeLabel.frame = CGRectMake(0, 0, labelWidth, self.bounds.size.height);
    self.playedTimeLabel.text  = playedText;

    self.durationLabel.frame = CGRectMake(self.bounds.size.width - labelWidth, 0, labelWidth, self.bounds.size.height);
    self.durationLabel.text  = durationText;

    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.backgroundColor setFill];
    CGContextFillRect(context, rect);
    CGFloat slidePosition    = self.value1;
    CGFloat progressPosition = MAX(self.value2, self.value1);

    CGFloat y         = floor(rect.size.height * 0.5) + 0.5 * kLineHeight;
    CGSize  slideSize = self.slideImage.size;

    CGContextSetLineWidth(context, kLineHeight);
    CGFloat startX = slideSize.width * 0.5 + self.timeLableWidth;
    CGFloat endX   = rect.size.width - slideSize.width * 0.5 - self.timeLableWidth;

    CGFloat lineStartX = self.timeLableWidth;
    CGFloat lineEndX   = rect.size.width - self.timeLableWidth;

    CGFloat centerX = slideSize.width * 0.5 + lineStartX + slidePosition * (lineEndX - lineStartX - slideSize.width);

    [self.maxColor setStroke];
    CGContextMoveToPoint(context, lineStartX + progressPosition * (lineEndX - lineStartX), y);
    CGContextAddLineToPoint(context, lineEndX, y);
    CGContextStrokePath(context);

    [self.midColor setStroke];
    CGContextMoveToPoint(context, centerX, y);
    CGContextAddLineToPoint(context, lineStartX + progressPosition * (lineEndX - lineStartX), y);
    CGContextStrokePath(context);

    [self.minColor setStroke];
    CGContextMoveToPoint(context, lineStartX, y);
    CGContextAddLineToPoint(context, centerX, y);
    CGContextStrokePath(context);

    [self.slideImage drawAtPoint:CGPointMake(centerX - slideSize.width * 0.5,
         y - slideSize.height * 0.5)];
    self.popView.text   = [NTYTimeConvert HHMMSSTextFromSeconds:self.maximumValue * self.value1];
    self.popView.center = CGPointMake(floor(startX + slidePosition * (endX - startX)), floor(y - 2 * slideSize.height));
    if (self.popView.frame.origin.x <= 0) {
        CGRect popViewFrame = self.popView.frame;
        popViewFrame.origin.x = 0;
        self.popView.frame    = popViewFrame;
    }

    if (self.popView.frame.origin.x + self.popView.frame.size.width > self.bounds.size.width) {
        CGRect popViewFrame = self.popView.frame;
        popViewFrame.origin.x = self.bounds.size.width - self.popView.frame.size.width;
        self.popView.frame    = popViewFrame;
    }
} /* drawRect */

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    return YES;
}

- (BOOL)beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event {
    CGPoint touchPoint = [touch locationInView:self];
    if (CGRectContainsPoint([self slidePointImageRect], touchPoint)) {
        [self showPopAnimated:YES];

        return YES;
    }

    return NO;
}

- (BOOL)continueTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event {
    CGPoint touchPoint = [touch locationInView:self];
    CGSize  slideSize  = self.slideImage.size;
    CGFloat startX     = slideSize.width * 0.5 + self.timeLableWidth;
    CGFloat endX       = self.bounds.size.width - slideSize.width * 0.5 - self.timeLableWidth;
    touchPoint.x = MAX(startX, touchPoint.x);
    touchPoint.x = MIN(endX, touchPoint.x);

    self.value1 = (touchPoint.x - startX) / (endX - startX);
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self setNeedsDisplay];

    return YES;
}

- (void)endTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event {
    [self hidePopAnimated:YES];
    // system automatically send a UIControlEventTouchUpInside
    // [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (CGRect)slidePointImageRect {
    CGSize  slideSize = self.slideImage.size;
    CGFloat startX    = slideSize.width * 0.5 + self.timeLableWidth;
    CGFloat endX      = self.bounds.size.width - slideSize.width * 0.5 - self.timeLableWidth;
    CGFloat y         = self.bounds.size.height * 0.5;

    CGRect  orgRect = CGRectMake(
        startX + self.value1 * (endX - startX) - slideSize.width * 0.5,
        y - slideSize.height * 0.5,
        slideSize.width,
        slideSize.height);

    CGFloat xScale = (kHitTestScale * orgRect.size.width - orgRect.size.width) * 0.5;
    CGFloat yScale = (kHitTestScale * orgRect.size.height - orgRect.size.height) * 0.5;

    CGRect  desRect = CGRectMake(orgRect.origin.x - xScale, orgRect.origin.y - yScale, kHitTestScale * orgRect.size.width, kHitTestScale * orgRect.size.height);

    return desRect;
}

- (void)showPopAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            self.popView.alpha = 1.f;
        }];
    } else {
        self.popView.alpha = 1.f;
    }
}

- (void)hidePopAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            self.popView.alpha = 0.f;
        }];
    } else {
        self.popView.alpha = 0.f;
    }
}

@end
