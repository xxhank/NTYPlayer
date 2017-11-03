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
#import "NTYTimer.h"
/**
 *  网络请求
 *
 *  @param url      请求的URL
 *  @param callback 请求的JS回调
 *  @param options  请求选项
 *  method NSString, GET(默认值), POST
 *  header NSDictionary, 默认是nil
 *  parameters NSDictionary, 默认值 nil
 *  body NSDictionary, 默认值nil
 */
typedef void (^JSAjax)(NSString *url, NSString *ajaxID, NSString *callback, NSDictionary *options);
typedef void (^JSParseCompletion)(NSDictionary*result);
@interface NewJSViewController ()
@property (nonatomic, strong) JSContext           *context;
@property (nonatomic, copy) JSAjax                 ajax;
@property (nonatomic, copy) JSParseCompletion      completion;
@property (nonatomic, strong) NSMutableDictionary *timers;
@property (nonatomic, weak) IBOutlet UITextView   *outputView;
//@property (nonatomic, strong) NSMutableArray    *request;
@end

@implementation NewJSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.outputView.text = @"";

    // self.request = [NSMutableArray arrayWithCapacity:0x10];

    self.context = [[JSContext alloc] init];
    @weakify(self);
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        @strongify(self);
        [self output_append:STRING(@"error: %@ %@", context, exception)];
    };
    self.context[@"console"][@"log"] = ^(NSString *message) {
        @strongify(self);
        [self output_append:STRING(@"console: %@", message)];
    };

    NSString *path     = [Path pathForResource:@"test.js"];
    NSString *jsString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.context evaluateScript:jsString];

    self.ajax = ^(NSString *url, NSString *ajaxID, NSString *callback, NSDictionary *options) {
        @strongify(self);
        NSLogInfo(@"callee:%@ \nthis:%@ \narguments%@",
            [[JSContext currentCallee] toString],
            [[JSContext currentThis] toString],
            [JSContext currentArguments]);

        NSLogInfo(@"need request %@ %@ %@ %@", url, ajaxID, callback, options);

        NTYExternSiteRequest *request = [[NTYExternSiteRequest alloc] initWithURL:url headers:nil];

        [request fetch:^(NTYResult*_Nonnull result) {
            NSString *value = [NSString cast:result.value];
            if (!value) {
                NSError *error = result.error?:NTYError(0, @"unknown error");
                NSLogError(@"%@",error);
                return;
            }

            JSValue *function = self.context[callback];
            JSValue *jsresult = [function callWithArguments:@[ajaxID, value]];
            NSLogInfo(@"%@", jsresult);
        }];
    };
    [self.context setObject:self.ajax forKeyedSubscript:@"bridge_ajax"];

    self.completion = ^(NSDictionary *result) {
        @strongify(self);
        [self output_append:STRING(@"result: %@", result)];
    };
    [self.context setObject:self.completion forKeyedSubscript:@"bridge_completion"];

    [self.context setObject:^NSString*(NSString*message, JSValue*callback) {
        [callback callWithArguments:@[STRING(@"got message from js:%@", message)]];
        return [[NSUUID UUID] UUIDString];
    } forKeyedSubscript:@"bridge_testcalllback"];

    self.context[@"setTimeout"] = ^NSString* (JSValue*function, JSValue*timeout, JSValue*context) {
        @strongify(self);
        NSString *timerID = [[NSUUID UUID] UUIDString];
        NTYTimer *timer   = [NTYTimer scheduleWithInterval:[timeout toDouble] / 1000.0 repeats:NO runloop:^(NSTimer *timer) {
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        } block:^(NTYTimer *timer) {
            if (context) {
                [function callWithArguments:@[context]];
            } else {
                [function callWithArguments:@[]];
            }
            [self.timers removeObjectForKey:timerID];
        }];
        self.timers[timerID] = timer;
        return timerID;
    };
    self.context[@"clearTimeout"] = ^(NSString *timerID) {
        @strongify(self);
        [self.timers removeObjectForKey:timerID];
    };
    //self.context[@"bridge"][@"ajax"]       = self.ajax;
    //self.context[@"bridge"][@"completion"] = self.completion;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testUseJS:(id)sender {
    self.outputView.text = @"";

    JSValue *function = self.context[@"parse"];

    JSValue *result = [function callWithArguments:@[@"http://www.baidu.com", @"http://www.163.com"]];
    [self output_append:[result toString]];
}
- (void)output_append:(NSString*)value {
    if (!value) {
        return;
    }
    NSString *old     = self.outputView.text?:@"";
    NSString *content = value;
    if (old.length > 0) {
        content = [@"\n" stringByAppendingString:value];
    }
    self.outputView.text = [old stringByAppendingString:content];
}
@end
