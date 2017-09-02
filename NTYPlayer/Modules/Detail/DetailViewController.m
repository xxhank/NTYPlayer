//
//  DetailViewController.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/2.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "DetailViewController.h"
#import "NTYTableViewProxy.h"

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
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NTYTableViewProxy  *proxy;

@end

@implementation DetailViewController
#pragma mark - Memory Management
- (void)didReceiveMemoryWarning {
}

- (void)dealloc {
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
}

- (void)loadNewData {
}

- (void)loadMoreData:(BOOL)prefetch {
}

#pragma mark - Override

#pragma mark - Feature 1

#pragma mark - Override
#pragma mark - Action
#pragma mark -
#pragma mark -

@end
