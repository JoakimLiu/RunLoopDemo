//
//  AppDelegate.m
//  RunLoopDemo
//
//  Created by Chun Ye on 10/20/14.
//  Copyright (c) 2014 Chun Tips. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CCTestRunLoopViewController.h"
#import "CCRunLoopThread.h"
#import "CCRunLoopCustomInputSourceThread.h"

#define kTestRunLoopThread 0
#define kTestCustomInputSpurceRunLoopThread 1

@interface CCAppDelegate ()

@property (nonatomic, strong) NSMutableArray *sources;

@end

@implementation CCAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    
    CCTestRunLoopViewController *testViewController = [[CCTestRunLoopViewController alloc] init];
    self.window.rootViewController = testViewController;
    
    [self.window makeKeyAndVisible];
    
    if (kTestRunLoopThread) {
        [self startRunLoopThread];
    }
    
    if (kTestCustomInputSpurceRunLoopThread) {
        [self startCustomInputSpurceRunLoopThread];
    }
    
    return YES;
}

#pragma mark - Private

- (void)startRunLoopThread
{
    CCRunLoopThread *runLoopThread = [[CCRunLoopThread alloc] init];
    [runLoopThread start];
}

- (void)startCustomInputSpurceRunLoopThread
{
    CCRunLoopCustomInputSourceThread *customInputSourceThread = [[CCRunLoopCustomInputSourceThread alloc] init];
    [customInputSourceThread start];
}

@end

/*
 要使输入源有用，需要对其进行操作，并从另一个线程发出信号。输入源的重点是将其关联的线程置于休眠状态，直到有事情要做才唤醒。所以，需要让应用程序中的其他线程知道输入源，并有办法与之通信。
 
 通知客户端输入源的一种方法是，在输入源首次安装在其 run loop 上时**发出注册请求**。 可以使用任意数量的客户端注册输入源，或者只需将其注册到某个中央代理商，然后将输入源发送给感兴趣的客户。下面代码显示了应用程序委托定义的注册方法，并在调用 RunLoopSource 对象的调度程序函数时调用。 此方法接收 RunLoopSource 对象提供的 RunLoopContext 对象，并将其添加到其源列表中。 还显示了从 run loop 中删除输入源时用于取消注册的程序。
 */
@implementation CCAppDelegate (RunLoop)

- (void)registerSource:(CCRunLoopContext *)sourceContext
{
    if (!self.sources) {
        self.sources = [NSMutableArray array];
    }
    [self.sources addObject:sourceContext];
}

- (void)removeSource:(CCRunLoopContext *)sourceContext
{
    [self.sources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CCRunLoopContext *context = obj;
        if ([context isEqual:sourceContext]) {
            [self.sources removeObject:context];
            *stop = YES;
        }
    }];
}

- (void)testInputSourceEvent
{
    CCRunLoopContext *runLoopContext = [self.sources objectAtIndex:0];
    CCRunLoopInputSource *inputSource = runLoopContext.runLoopInputSource;
    [inputSource addTestPrintCommandWithString:[[NSDate date] description]];
    [inputSource fireAllCommandsOnRunLoop:runLoopContext.runLoop];
}

@end
