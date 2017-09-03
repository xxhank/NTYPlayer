//
//  LePlayerProgressPopoverView.m
//  LePlayer
//
//  Created by CaiLei on 4/14/14.
//  Copyright (c) 2014 Le123. All rights reserved.
//

#import "NTYProgressPopover.h"

@implementation UIBezierPath (IOS7RoundedRect)

#define TOP_LEFT(X, Y)     CGPointMake(rect.origin.x + X * limitedRadius, rect.origin.y + Y * limitedRadius)
#define TOP_RIGHT(X, Y)    CGPointMake(rect.origin.x + rect.size.width - X * limitedRadius, rect.origin.y + Y * limitedRadius)
#define BOTTOM_RIGHT(X, Y) CGPointMake(rect.origin.x + rect.size.width - X * limitedRadius, rect.origin.y + rect.size.height - Y * limitedRadius)
#define BOTTOM_LEFT(X, Y)  CGPointMake(rect.origin.x + X * limitedRadius, rect.origin.y + rect.size.height - Y * limitedRadius)


+ (UIBezierPath*)bezierPathWithIOS7RoundedRect:(CGRect)rect cornerRadius:(CGFloat)radius;
{
    UIBezierPath *path          = UIBezierPath.bezierPath;
    CGFloat       limit         = MIN(rect.size.width, rect.size.height) / 2 / 1.52866483;
    CGFloat       limitedRadius = MIN(radius, limit);

    [path moveToPoint:TOP_LEFT(1.52866483, 0.00000000)];
    [path addLineToPoint:TOP_RIGHT(1.52866471, 0.00000000)];
    [path addCurveToPoint:TOP_RIGHT(0.66993427, 0.06549600)
            controlPoint1:TOP_RIGHT(1.08849323, 0.00000000)
            controlPoint2:TOP_RIGHT(0.86840689, 0.00000000)];
    [path addLineToPoint:TOP_RIGHT(0.63149399, 0.07491100)];
    [path addCurveToPoint:TOP_RIGHT(0.07491176, 0.63149399)
            controlPoint1:TOP_RIGHT(0.37282392, 0.16905899)
            controlPoint2:TOP_RIGHT(0.16906013, 0.37282401)];
    [path addCurveToPoint:TOP_RIGHT(0.00000000, 1.52866483)
            controlPoint1:TOP_RIGHT(0.00000000, 0.86840701)
            controlPoint2:TOP_RIGHT(0.00000000, 1.08849299)];
    [path addLineToPoint:BOTTOM_RIGHT(0.00000000, 1.52866471)];
    [path addCurveToPoint:BOTTOM_RIGHT(0.06549569, 0.66993493)
            controlPoint1:BOTTOM_RIGHT(0.00000000, 1.08849323)
            controlPoint2:BOTTOM_RIGHT(0.00000000, 0.86840689)];
    [path addLineToPoint:BOTTOM_RIGHT(0.07491111, 0.63149399)];
    [path addCurveToPoint:BOTTOM_RIGHT(0.63149399, 0.07491111)
            controlPoint1:BOTTOM_RIGHT(0.16905883, 0.37282392)
            controlPoint2:BOTTOM_RIGHT(0.37282392, 0.16905883)];
    [path addCurveToPoint:BOTTOM_RIGHT(1.52866471, 0.00000000)
            controlPoint1:BOTTOM_RIGHT(0.86840689, 0.00000000)
            controlPoint2:BOTTOM_RIGHT(1.08849323, 0.00000000)];
    [path addLineToPoint:BOTTOM_LEFT(1.52866483, 0.00000000)];
    [path addCurveToPoint:BOTTOM_LEFT(0.66993397, 0.06549569)
            controlPoint1:BOTTOM_LEFT(1.08849299, 0.00000000)
            controlPoint2:BOTTOM_LEFT(0.86840701, 0.00000000)];
    [path addLineToPoint:BOTTOM_LEFT(0.63149399, 0.07491111)];
    [path addCurveToPoint:BOTTOM_LEFT(0.07491100, 0.63149399)
            controlPoint1:BOTTOM_LEFT(0.37282401, 0.16905883)
            controlPoint2:BOTTOM_LEFT(0.16906001, 0.37282392)];
    [path addCurveToPoint:BOTTOM_LEFT(0.00000000, 1.52866471)
            controlPoint1:BOTTOM_LEFT(0.00000000, 0.86840689)
            controlPoint2:BOTTOM_LEFT(0.00000000, 1.08849323)];
    [path addLineToPoint:TOP_LEFT(0.00000000, 1.52866483)];
    [path addCurveToPoint:TOP_LEFT(0.06549600, 0.66993397)
            controlPoint1:TOP_LEFT(0.00000000, 1.08849299)
            controlPoint2:TOP_LEFT(0.00000000, 0.86840701)];
    [path addLineToPoint:TOP_LEFT(0.07491100, 0.63149399)];
    [path addCurveToPoint:TOP_LEFT(0.63149399, 0.07491100)
            controlPoint1:TOP_LEFT(0.16906001, 0.37282401)
            controlPoint2:TOP_LEFT(0.37282401, 0.16906001)];
    [path addCurveToPoint:TOP_LEFT(1.52866483, 0.00000000)
            controlPoint1:TOP_LEFT(0.86840701, 0.00000000)
            controlPoint2:TOP_LEFT(1.08849299, 0.00000000)];
    [path closePath];

    return path;
}

@end

static const CGFloat kGap        = 5;
static const CGFloat kLineHeight = 1;

@implementation NTYProgressPopover
- (void)setText:(NSString*)text {
    _text       = text;
    self.bounds = CGRectMake(0, 0, [self sizeForView].width, [self sizeForView].height + kLineHeight);
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont*)font {
    _font       = font;
    self.bounds = CGRectMake(0, 0, [self sizeForView].width, [self sizeForView].height + kLineHeight);
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _font                = [UIFont systemFontOfSize:12.f];
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] setFill];
    CGContextFillRect(context, rect);

    UIBezierPath *path    = [UIBezierPath bezierPathWithIOS7RoundedRect:rect cornerRadius:2.0];
    UIColor      *bgColor = [COLOR_HEX(0x000000) colorWithAlphaComponent:0.25];
    [bgColor setFill];
    [path fill];

    UIColor *fgColor = [COLOR_HEX(0xffffff) colorWithAlphaComponent:0.2];
    [fgColor setStroke];
    [path stroke];

    [self.text drawAtPoint:CGPointMake(kGap, 0) withAttributes:@{NSFontAttributeName:self.font,
                                                                 NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (CGSize)sizeForView {
    CGSize size = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}];

    return CGSizeMake(ceil(size.width) + 2 * kGap, ceil(size.height));
}

+ (NSString*)stringFromSecond:(NSTimeInterval)aSecond {
    long int  second = lround(aSecond);
    long int  toHour = second / (60 * 60);

    long int  toMinute = (second / 60) - (toHour * 60);
    long int  toSecond = second % 60;
    NSString *retString;
    if (toHour) {
        retString = [NSString stringWithFormat:@"%01ld:%02ld:%02ld", toHour, toMinute, toSecond];
    } else {
        retString = [NSString stringWithFormat:@"%02ld:%02ld", toMinute, toSecond];
    }

    return retString;
}

@end
