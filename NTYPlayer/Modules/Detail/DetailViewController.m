//
//  DetailViewController.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "DetailViewController.h"
#import "NTYTableViewProxy.h"
#import "NTYPlayer.h"
#import "NSString+NTYExtension.h"
#import "Path.h"

@interface DetailContentCellViewModel : NSObject<NTYTableViewCellViewModel>
@property (nonatomic, strong) NSString *title;
@end

@implementation DetailContentCellViewModel
- (instancetype)initWithTitle:(NSString*)title {
    self = [super init];
    if (self) {
        _title = title;
    }
    return self;
}
- (CGFloat)cellHeight {return 60;}
@end

#define CELLVIEWMODEL(title) [[DetailContentCellViewModel alloc] initWithTitle: title]

@interface DetailContentCell : UITableViewCell<NTYSupportViewModel>
@end

@implementation DetailContentCell
- (void)setViewModel:(DetailContentCellViewModel*)viewModel {
    self.textLabel.text = viewModel.title;
}
@end


@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIView      *playerContrainer;
@property (weak, nonatomic) IBOutlet UIView      *playerActionView;
@property (weak, nonatomic) IBOutlet UIView      *playerBottomView;

@property (nonatomic, weak) IBOutlet UIButton    *playButton;

@property (nonatomic, weak) IBOutlet UILabel     *playedTimeLabel;
@property (nonatomic, weak) IBOutlet UISlider    *processView;
@property (nonatomic, weak) IBOutlet UILabel     *totalDurationLabel;

@property (nonatomic, weak) IBOutlet UIButton    *fullsceendButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UISlider    *volumeView;

@property (nonatomic, strong) NTYTableViewProxy  *proxy;
@property (nonatomic, strong) NTYPlayer          *player;
@end

@implementation DetailViewController
#pragma mark - Memory Management
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSLogInfo(@"");
    [self.player stop];
}

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews {
}

- (void)viewDidLayoutSubviews {
}

#pragma mark - Build
- (void)buildUI {
    self.proxy = [NTYTableViewProxy proxy:self.tableView];
    [self.proxy updateViewModels:@[
         CELLVIEWMODEL(@"Album"),
         CELLVIEWMODEL(@"Episodes"),
         CELLVIEWMODEL(@"Relate")
     ]];

    self.tableView.tableFooterView = [UIView new];

    self.player = [[NTYPlayer alloc] init];

    [self.playerContrainer insertSubview:self.player.contentView atIndex:0];
    [self.player.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playerContrainer);
    }];

    self.volumeView.value = self.player.volume;

    NSString *path = [Path pathForResource:@"video.list"];
    NSArray  *urls = [[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
    NTYAssertNotNil(urls);
    NSArray  *durations = @[@(297.813354),
                            @(300.76001),
                            @(298.965332),
                            @(301.359985),
                            @(297.480011),
                            @(299.946655),
                            @(303.160004),
                            @(298.282654),
                            @(483.797333)];
    [self.player playWithURLs:urls position:0 durations:durations headers:nil];
    @weakify(self);
    self.player.stateUpdated = ^(NTYPlayerState state) {
        @strongify(self);
        [Dispatch ui:^{
            self.title = NTYPlayerStateStringify(state);
        }];
    };
    self.player.durationUpdated = ^(NSTimeInterval totalDuration) {
        @strongify(self);
        [Dispatch ui:^{
            self.totalDurationLabel.text = NSStringFromDuration(totalDuration);
            self.processView.minimumValue = 0;
            self.processView.maximumValue = totalDuration;
        }];
    };

    self.player.playedUpdated = ^(NSTimeInterval played) {
        @strongify(self);
        [Dispatch ui:^{
            self.processView.value = played;
            self.playedTimeLabel.text = NSStringFromDuration(played);
        }];
    };
}

- (void)loadNewData {
}

- (void)loadMoreData:(BOOL)prefetch {
}

#pragma mark - Override
#pragma mark - Action
- (IBAction)playVideo:(id)sender {
    if (self.player.state == NTYPlayerStatePlaying) {
        [self.player pause];
    } else if (self.player.state == NTYPlayerStatePaused) {
        [self.player resume];
    } else {
        NSLogWarn(@"unsupport state %@", NTYPlayerStateStringify(self.player.state));
    }
}

- (IBAction)fullScreen:(id)sender {
}

- (IBAction)seekVideo:(UISlider*)sender {
    [self.player pause];
    NSTimeInterval position = sender.value;
    [self.player seek:position];
}

- (IBAction)volumeVideo:(UISlider*)sender {
    CGFloat value = sender.value;
    self.player.volume = value;
}

#pragma mark - Help
NSString*NSStringFromDuration(NSTimeInterval totalDuration) {
    const NSUInteger SecondsPerHour   = 60 * 60;
    const NSUInteger SecondsPerMinute = 60;

    NSUInteger       hour    = totalDuration / SecondsPerHour;
    NSUInteger       left    = totalDuration - hour * SecondsPerHour;
    NSUInteger       minutes = left / SecondsPerMinute;
    NSUInteger       seconds = left - minutes * SecondsPerMinute;
    if (hour > 0) {
        return STRING(@"%02zd:%02zd:%02zd", hour, minutes, seconds);
    } else {
        return STRING(@"%02zd:%02zd", minutes, seconds);
    }
};

#pragma mark - Feature 1
#pragma mark - Override
#pragma mark - Action
#pragma mark -
#pragma mark -

@end
