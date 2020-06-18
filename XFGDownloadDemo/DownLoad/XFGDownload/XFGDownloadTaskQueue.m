//
//  XFGDownloadTaskQueue.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadTaskQueue.h"

@interface XFGDownloadTaskQueue ()
@property (nonatomic, strong) NSMutableArray <XFGDownloadTask *> * tasks;

@property (nonatomic, assign) NSTimeInterval archiveTimeInterval;
@property (nonatomic, copy) NSString * archiverPath;
@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, assign) BOOL closed;
@end

@implementation XFGDownloadTaskQueue

#pragma mark - init
+(instancetype)queueWithDownload:(XFGDownload*)download{
    return [[self alloc]init];
}

-(instancetype)initWithDownload:(XFGDownload*)download{
    if (self = [super init]) {
        self.download = download;
        self.archiverPath = [XFGDownloadTools archiverFilePathWithIdentifier:download.identifier];
        if (self.tasks) {
            self.tasks = [NSMutableArray array];
        }
        self.condition = [[NSCondition alloc]init];
        [self resetQueue];
    }
    return self;
}

- (nullable XFGDownloadTask *)taskForContentURL:(NSURL *)contentURL{
    if (contentURL.absoluteString.length<=0) {
        return nil;
    }
    [self.condition lock];
    XFGDownloadTask *task = nil;
    for (XFGDownloadTask *eachTask in self.tasks) {
        if ([eachTask.contentURL.absoluteString isEqualToString:contentURL.absoluteString]) {
            task = eachTask;
            break;
        }
    }
    [self.condition unlock];
    return task;
}
- (nullable NSArray <XFGDownloadTask *> *)tasksForAll{
    if (self.tasks.count>0) {
        return [self.tasks copy];
    }
    return nil;
}
- (nullable NSArray <XFGDownloadTask *> *)tasksForRunning{
    [self.condition lock];
    NSMutableArray *temp = [NSMutableArray array];
    for (XFGDownloadTask *task in self.tasks) {
        if (task.state == XFGDownloadTaskStateRunning) {
            [temp addObject:task];
        }
    }
    if (temp.count<=0) {
        temp = nil;
    }
    [self.condition unlock];
    if (temp.count>0) {
        return [temp copy];
    }
    return nil;
}
- (nullable NSArray <XFGDownloadTask *> *)tasksForRunningOrWatting{
    [self.condition lock];
    NSMutableArray *temp = [NSMutableArray array];
    for (XFGDownloadTask *task in self.tasks) {
        if (task.state == XFGDownloadTaskStateRunning||task.state == XFGDownloadTaskStateWaiting) {
            [temp addObject:task];
        }
    }
    if (temp.count<=0) {
        temp = nil;
    }
    [self.condition unlock];
    if (temp.count>0) {
        return [temp copy];
    }
    return nil;
}
- (nullable NSArray <XFGDownloadTask *> *)tasksForState:(XFGDownloadTaskState)state{
    [self.condition lock];
    NSMutableArray *temp = [NSMutableArray array];
    for (XFGDownloadTask *task in self.tasks) {
        if (task.state == state) {
            [temp addObject:task];
        }
    }
    if (temp.count<=0) {
        temp = nil;
    }
    [self.condition unlock];
    if (temp.count>0) {
        return [temp copy];
    }
    return nil;
}

- (void)setTaskStateWithTask:(XFGDownloadTask *)task state:(XFGDownloadTaskState)state{
    if (!task) return;
    if (task.state == state) return;
    //条件锁
    [self.condition lock];
    task.state = state;
    [self.condition unlock];
    //归档一次
    [self tryArchive];
}

- (nullable XFGDownloadTask *)downloadTaskSync{
    if (self.closed) return nil;
    //又是一个条件锁
    [self.condition lock];
    XFGDownloadTask * task;
    do {
        for (XFGDownloadTask * obj in self.tasks) {
            if (self.closed) {
                [self.condition unlock];
                return nil;
            }
            switch (obj.state) {
                case XFGDownloadTaskStateNone:
                case XFGDownloadTaskStateWaiting:
                    task = obj;
                    break;
                default:
                    break;
            }
            if (task) break;
        }
        //为空，
        if (!task) {
            //阻塞掉了
            [self.condition wait];
        }
    } while (!task);
    [self.condition unlock];
    return task;
}


#pragma mark - 添加task
- (void)addDownloadTask:(XFGDownloadTask *)task
{
    if (task) {
        [self addDownloadTasks:@[task]];
    }
}

- (void)addDownloadTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    if (self.closed) return;
    if (tasks.count <= 0) return;
    [self.condition lock];
    BOOL needSignal = NO;
    for (XFGDownloadTask * obj in tasks) {
        if (![self.tasks containsObject:obj]) {
            obj.download = self.download;
            [self.tasks addObject:obj];
        }
        switch (obj.state) {
            case XFGDownloadTaskStateNone:
            case XFGDownloadTaskStateSuspend:
            case XFGDownloadTaskStateCanceled:
            case XFGDownloadTaskStateFailured:
                obj.state = XFGDownloadTaskStateWaiting; //进入等待
                needSignal = YES;
                break;
            default:
                break;
        }
    }
    //
    if (needSignal) {
        //发送了信号-- 唤醒当前
        [self.condition signal];
    }
    [self.condition unlock];
    [self tryArchive];
}

#pragma mark - 执行下载

- (void)resumeAllTasks
{
    [self resumeTasks:self.tasks];
}

- (void)resumeTask:(XFGDownloadTask *)task
{
    if (task) {
        [self resumeTasks:@[task]];
    }
}

- (void)resumeTasks:(NSArray<XFGDownloadTask *> *)tasks
{
    if (self.closed) return;
    if (tasks.count <= 0) return;
    [self.condition lock];
    BOOL needSignal = NO;
    for (XFGDownloadTask * task in tasks) {
        switch (task.state) {
            case XFGDownloadTaskStateNone:
            case XFGDownloadTaskStateSuspend:
            case XFGDownloadTaskStateCanceled:
            case XFGDownloadTaskStateFailured:
                task.state = XFGDownloadTaskStateWaiting;
                needSignal = YES;
                break;
            default:
                break;
        }
    }
    if (needSignal) {
        [self.condition signal];
    }
    [self.condition unlock];
    [self tryArchive];
}

#pragma mark - 暂停
- (void)suspendAllTasks
{
    [self suspendTasks:self.tasks];
}

- (void)suspendTask:(XFGDownloadTask *)task
{
    if (task) {
        [self suspendTasks:@[task]];
    }
}

- (void)suspendTasks:(NSArray<XFGDownloadTask *> *)tasks
{
    if (tasks.count <= 0) return;
    [self.condition lock];
    for (XFGDownloadTask * task in tasks) {
        switch (task.state) {
            case XFGDownloadTaskStateNone:
            case XFGDownloadTaskStateWaiting:
            case XFGDownloadTaskStateRunning:
                task.state = XFGDownloadTaskStateSuspend;
                break;
            default:
                break;
        }
    }
    [self.condition unlock];
    [self tryArchive];
}
#pragma mark - cancel(取消)
- (void)cancelAllTasks
{
    [self cancelTasks:self.tasks];
}

- (void)cancelTask:(XFGDownloadTask *)task
{
    if (task) {
        [self cancelTasks:@[task]];
    }
}

- (void)cancelTasks:(NSArray<XFGDownloadTask *> *)tasks
{
    if (tasks.count <= 0) return;
    [self.condition lock];
    NSMutableArray <XFGDownloadTask *> * temp = [NSMutableArray array];
    for (XFGDownloadTask * task in tasks) {
        if ([self.tasks containsObject:task]) {
            task.state = XFGDownloadTaskStateCanceled;
            [temp addObject:task];
        }
    }
    for (XFGDownloadTask * task in temp) {
        task.download = nil;
        [self.tasks removeObject:task];
    }
    [self.condition unlock];
    [self tryArchive];
}

#pragma mark - delete(删除)
- (void)deleteAllTaskFiles
{
    [self deleteTaskFiles:self.tasks];
}

- (void)deleteTaskFile:(XFGDownloadTask *)task
{
    if (task) {
        [self deleteTaskFiles:@[task]];
    }
}

- (void)deleteTaskFiles:(NSArray <XFGDownloadTask *> *)tasks
{
    if (tasks.count <= 0) return;
    [self.condition lock];
    for (XFGDownloadTask * task in tasks) {
        if ([self.tasks containsObject:task]) {
            [XFGDownloadTools removeFileWithFileURL:task.fileURL];
            task.fileDidRemoved = YES;
        }
    }
    [self.condition unlock];
    /*
     [self tryArchive];
     */
}

#pragma mark - invalidate
- (void)invalidate{
    if (self.closed) return;
    
    [self.condition lock];
    self.closed = YES;
    for (XFGDownloadTask * task in self.tasks) {
        switch (task.state) {
            case XFGDownloadTaskStateRunning:
                task.state = XFGDownloadTaskStateWaiting;
                break;
            default:
                break;
        }
    }
    [self.condition broadcast];
    [self.condition unlock];
    [self archive];
}

#pragma mark - archive
-(void)archive{
    [self.condition lock];
    [NSKeyedArchiver archiveRootObject:self.tasks toFile:self.archiverPath];
    self.archiveTimeInterval = [NSDate date].timeIntervalSince1970;
    [self.condition unlock];
}


#pragma mark -  Tools
-(void)resetQueue{
    [self.condition lock];
    for (XFGDownloadTask *obj in self.tasks) {
        obj.download = self.download;
        if (obj.state == XFGDownloadTaskStateRunning) {
            obj.state = XFGDownloadTaskStateWaiting;
        }
    }
    [self.condition unlock];
    [self tryArchive];
}


-(void)tryArchive{
    NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (timeInterval > self.archiveTimeInterval) {
            [self archive];
        }
    });
}

#pragma mark - dealloc

-(void)dealloc{
    [self invalidate];
}


@end
