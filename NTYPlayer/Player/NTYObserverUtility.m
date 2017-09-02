//
//  NTYObserverUtility.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NTYObserverUtility.h"
@interface NTYNotificationObserver ()
@property (nonatomic, strong) NSNotificationName        name;
@property (nonatomic, strong) id                        source;
@property (nonatomic,copy) NTYNotificationAction action;
@property (atomic, assign) BOOL                         disposed;
@end

@implementation NTYNotificationObserver
- (instancetype)initWithName:(NSNotificationName)name source:(id)source action:(NTYNotificationAction)block {
    self = [super init];
    if (self) {
        self.name   = name;
        self.source = source;
        self.action = block;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle:)name:name object:source];
    }
    return self;
}

- (void)dealloc {
    [self dispose];
}

- (void)handle:(NSNotification*)notification {
    if (self.disposed) {return;}
    self.action(notification);
}

- (void)dispose {
    if (self.disposed) {return;}
    self.disposed = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:self.name object:self.source];
}
@end


@interface NTYSingleKeyValueObserver ()
@property (nonatomic,strong) NSString              *keyPath;
@property (nonatomic,strong) id                     target;
@property (nonatomic,copy) NTYKeyValueAction action;
@property (atomic, assign) BOOL                     disposed;
@end

@implementation NTYSingleKeyValueObserver
- (instancetype)initWithKeyPath:(nonnull NSString*)keyPath target:(id)target action:(NTYKeyValueAction)block {
    self = [super init];
    if (self) {
        self.keyPath = keyPath;
        self.target  = target;
        self.action  = block;
        [target addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

- (void)dealloc {
    [self dispose];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id>*)change context:(void*)context {
    if (![keyPath isEqualToString:self.keyPath]) {
        return;
    }

    NSNumber*new = [change valueForKey:NSKeyValueChangeNewKey];
    NSNumber*old = [change valueForKey:NSKeyValueChangeOldKey];
    if (self.disposed) {return;}
    self.action(new, old);
}

- (void)dispose {
    if (self.disposed) {return;}
    self.disposed = YES;
    [self.target removeObserver:self forKeyPath:self.keyPath];
}
@end
