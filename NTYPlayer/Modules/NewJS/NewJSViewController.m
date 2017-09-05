//
//  NewJSViewController.m
//  NTYPlayer
//
//  Created by wangchao on 2017/9/5.
//  Copyright © 2017年 ibestv. All rights reserved.
//

#import "NewJSViewController.h"
@import JavaScriptCore;
#import "DQRequests.h"
/**
 *  网络请求
 *
 *  @param url      请求的URL
 *  @param callback 请求的JS回调
 *  @param options  请求选项
    method NSString, GET(默认值), POST
    header NSDictionary, 默认是nil
    parameters NSDictionary, 默认值 nil
    body NSDictionary, 默认值nil
 */
typedef void (^JSAjax)(NSString *url,NSString *callback, NSDictionary *options);
@interface NewJSViewController ()
@property (nonatomic, strong) JSContext         *context;
@property (nonatomic, copy) JSAjax               ajax;
@property (nonatomic, weak) IBOutlet UITextView *outputView;
@property (nonatomic, strong) NSMutableArray    *request;
@end

@implementation NewJSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.request = [NSMutableArray arrayWithCapacity:0x10];

    self.context                  = [[JSContext alloc] init];
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSLogError(@"%@ %@", context, exception);
    };
    self.context[@"console"][@"log"] = ^(NSString *message) {
        NSLog(@"JS Console: %@", message);
    };
    NSString*path     = [Path pathForResource:@"test.js"];
    NSString*jsString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.context evaluateScript:jsString];

    @weakify(self);
    self.ajax = ^(NSString *url, NSString *callback, NSDictionary *options) {
        @strongify(self);
        NSLogInfo(@"need request %@ %@ %@", url, callback, options);
        NTYExternSiteRequest *request = [[NTYExternSiteRequest alloc] initWithURL:url headers:nil];

        [request fetch:^(NTYResult*_Nonnull result) {
            NSString *value = [NSString cast:result.value];
            if (!value) {
                NSError *error = result.error?:NTYError(0, @"unknown error");
                NSLogError(@"%@",error);
                return;
            }

            JSValue *function = self.context[callback];
            JSValue *jsresult = [function callWithArguments:@[value]];
            NSLogInfo(@"%@", jsresult);
        }];
    };
    [self.context setObject:self.ajax forKeyedSubscript:@"ajax"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testUseJS:(id)sender {
    JSValue *function = self.context[@"parse"];

    JSValue *result = [function callWithArguments:@[@"http://www.baidu.com", @"http://www.163.com"]];
    self.outputView.text = STRING(@"%@", [result toString]);
}

@end
