//
//  CCRunLoopInputSource.m
//  RunLoopDemo
//
//  Created by Chun Ye on 10/20/14.
//  Copyright (c) 2014 Chun Tips. All rights reserved.
//

#import "CCRunLoopInputSource.h"
#import "CCAppDelegate.h"

@interface CCRunLoopInputSource ()
{
    CFRunLoopSourceRef _runLoopSource;
    NSMutableArray *_commands;
    NSString *_testPrintString;
}

@end

/* Run Loop Source Context的三个回调方法 */

// 当把当前的Run Loop Source添加到Run Loop中时，会回调这个方法。主线程管理该Input source，所以使用performSelectorOnMainThread通知主线程。主线程和当前线程的通信使用CCRunLoopContext对象来完成。 (Note: 输入源只有一个客户端，那就是主线程，所以将 RunLoopContext 传递过去，方便 delegate 和输入源通信。)
void runLoopSourceScheduleRoutine (void *info, CFRunLoopRef runLoopRef, CFStringRef mode)
{
    CCRunLoopInputSource *runLoopInputSource = (__bridge CCRunLoopInputSource *)info;
    CCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    CCRunLoopContext *runLoopContext = [[CCRunLoopContext alloc] initWithSource:runLoopInputSource runLoop:runLoopRef];
    [appDelegate performSelectorOnMainThread:@selector(registerSource:) withObject:runLoopContext waitUntilDone:NO];
}

// 当前Input source被告知需要处理事件的回调方法
void runLoopSourcePerformRoutine (void *info)
{
    CCRunLoopInputSource *runLoopInputSource = (__bridge CCRunLoopInputSource *)info;
    [runLoopInputSource inputSourceFired];
}

// 如果使用CFRunLoopSourceInvalidate函数把输入源从Run Loop里面移除的话,系统会回调该方法。我们在该方法中移除了主线程对当前Input source context的引用。
void runLoopSourceCancelRoutine (void *info, CFRunLoopRef runLoopRef, CFStringRef mode)
{
    CCRunLoopInputSource *runLoopInputSource = (__bridge CCRunLoopInputSource *)info;
    CCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    CCRunLoopContext *runLoopContext = [[CCRunLoopContext alloc] initWithSource:runLoopInputSource runLoop:runLoopRef];
    [appDelegate performSelectorOnMainThread:@selector(removeSource:) withObject:runLoopContext waitUntilDone:YES];
}

@implementation CCRunLoopInputSource

#pragma mark - Public

- (instancetype)init
{
    self = [super init];
    if (self) {
        CFRunLoopSourceContext context = {0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL,
            &runLoopSourceScheduleRoutine,
            &runLoopSourceCancelRoutine,
            &runLoopSourcePerformRoutine};
        
        // 该类型必须附加到 run loop 中，将 RunLoopSource 对象本身作为上下文信息传递，以便回调程序具有指向该对象的指针。
        _runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
        
        _commands = [NSMutableArray array];
    }
    return self;
}

/**
 一旦调用此方法，就会调用 `RunLoopSourceScheduleRoutine` 回调函数。 一旦输入源被添加到 run loop 中，线程就可以运行其 run loop 来等待它。
 */
- (void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
}

- (void)invalidate
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopRemoveSource(runLoop, _runLoopSource, kCFRunLoopDefaultMode);
}

- (void)inputSourceFired
{
    NSLog(@"Enter inputSourceFired");
    
    // Test
    if (_testPrintString) {
        if ([self.delegate respondsToSelector:@selector(activeInputSourceForTestPrintStringEvent:)]) {
            [self.delegate activeInputSourceForTestPrintStringEvent:_testPrintString];
        }
    }
    
    NSLog(@"Exit inputSourceFired");
}

- (void)addCommand:(NSInteger)command data:(NSData *)data
{
    
}

- (void)addTestPrintCommandWithString:(NSString *)string
{
    NSLog(@"Current Thread: %@", [NSThread currentThread]);
    _testPrintString = string;
}

/*
 在将数据移交给输入源之后，客户端必须向源发信号并唤醒其 run loop 。 信号源使 run loop 知道源已准备好进行处理。 并且因为线程可能在信号发生时处于睡眠状态，所以手动唤醒 run loop 。 如果不这样做可能会导致处理输入源的延迟。
 */
- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runLoop
{
    NSLog(@"Current Thread: %@", [NSThread currentThread]);

    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(runLoop);
}

@end

@implementation CCRunLoopContext

- (instancetype)initWithSource:(CCRunLoopInputSource *)runLoopInputSource runLoop:(CFRunLoopRef)runLoop
{
    self = [super init];
    if (self) {
        _runLoopInputSource = runLoopInputSource;
        _runLoop = runLoop;
    }
    return self;
}

@end
