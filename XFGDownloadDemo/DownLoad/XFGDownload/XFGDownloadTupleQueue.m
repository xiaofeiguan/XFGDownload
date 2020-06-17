//
//  XFGDownloadTupleQueue.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadTupleQueue.h"

@interface XFGDownloadTupleQueue ()

@property (nonatomic, strong) NSLock * tupleLock; //上锁

@end

@implementation XFGDownloadTupleQueue

-(instancetype)init{
    if (self = [super init]) {
        self->_tuples = [NSMutableArray array];
        self.tupleLock = [[NSLock alloc]init];
    }
    return self;
}

-(XFGDownloadTaskTuple *)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask{
    [self.tupleLock lock];
    XFGDownloadTaskTuple *tuple = nil;
    for (XFGDownloadTaskTuple *eachTuple in self.tuples) {
        if (tuple.downloadTask == downloadTask) {
            tuple = eachTuple;
            break;
        }
    }
    [self.tupleLock unlock];
    return tuple;
}


-(NSArray<XFGDownloadTaskTuple *> *)tuplesWithDownloadTasks:(NSArray<XFGDownloadTask *> *)downloadTasks{
    [self.tupleLock lock];
    NSMutableArray *temps = [NSMutableArray array];
    for (XFGDownloadTaskTuple *eachTuple in self.tuples) {
        if ([downloadTasks containsObject:eachTuple.downloadTask]) {
            [temps addObject:eachTuple];
        }
    }
    [self.tupleLock unlock];
    return temps;
}

- (XFGDownloadTaskTuple *)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask sessionTask:(NSURLSessionDownloadTask *)sessionTask
{
    if (!downloadTask) {
        return nil;
    }
    XFGDownloadTaskTuple * tuple = [self tupleWithDownloadTask:downloadTask];
    if (tuple) {
        return tuple;
    }
    [self.tupleLock lock];
    XFGDownloadTaskTuple *extractedExpr = [XFGDownloadTaskTuple tupleWithDownloadTask:downloadTask sessionTask:sessionTask];
    tuple = extractedExpr;
    [self.tuples addObject:tuple];
    [self.tupleLock unlock];
    return tuple;
}


- (void)addTuple:(XFGDownloadTaskTuple *)tuple
{
    [self.tupleLock lock];
    if (![self.tuples containsObject:tuple]) {
        [self.tuples addObject:tuple];
    }
    [self.tupleLock unlock];
}

- (void)removeTupleWithSesstionTask:(NSURLSessionTask *)sessionTask{
    if (!sessionTask) {
        return ;
    }
    [self.tupleLock lock];
    XFGDownloadTaskTuple *tuple = nil;
    for (XFGDownloadTaskTuple *eachTuple in self.tuples) {
        if (eachTuple.sessionTask == sessionTask) {
            tuple = eachTuple;
            break;
        }
    }
    if (tuple) {
        [self.tuples removeObject:tuple];
    }
    [self.tupleLock unlock];
}

- (void)removeTuple:(XFGDownloadTaskTuple *)tuple
{
    if (tuple) {
        [self removeTuples:@[tuple]];
    }
}

- (void)removeTuples:(NSArray<XFGDownloadTaskTuple *> *)tuples
{
    if (tuples.count <= 0) return;
    [self.tupleLock lock];
    if (self.tuples == tuples) {
        [self.tuples removeAllObjects];
    } else {
        for (XFGDownloadTaskTuple * obj in tuples) {
            if ([self.tuples containsObject:obj]) {
                [self.tuples removeObject:obj];
            }
        }
    }
    [self.tupleLock unlock];
}


- (void)cancelDownloadTask:(XFGDownloadTask *)downloadTask resume:(BOOL)resume completionHandler:(void(^)(XFGDownloadTaskTuple * tuple))completionHandler{
    XFGDownloadTaskTuple *tuple = [self tupleWithDownloadTask:downloadTask];
    [self cancelTuple:tuple resume:resume completionHandler:completionHandler];
}


- (void)cancelDownloadTasks:(NSArray <XFGDownloadTask *> *)downloadTasks resume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler{
    NSArray *tuples = [self tuplesWithDownloadTasks:downloadTasks];
    [self cancelTuples:tuples resume:resume completionHandler:completionHandler];
}

- (void)cancelAllTupleResume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler{
    [self cancelTuples:self.tuples resume:resume completionHandler:completionHandler];
}
//取消
- (void)cancelTuple:(XFGDownloadTaskTuple *)tuple resume:(BOOL)resume completionHandler:(void(^)(XFGDownloadTaskTuple * tuple))completionHandler{
    if (tuple) {
        [self cancelTuples:@[tuple] resume:resume completionHandler:^(NSArray<XFGDownloadTaskTuple *> * tuples) {
            if (completionHandler) {
                completionHandler(tuples.firstObject);
            }
        }];
    } else {
        [self cancelTuples:nil resume:resume completionHandler:^(NSArray<XFGDownloadTaskTuple *> * tuples) {
            if (completionHandler) {
                completionHandler(tuples.firstObject);
            }
        }];
    }
}



// 具体实现
- (void)cancelTuples:(NSArray <XFGDownloadTaskTuple *> *)tuples resume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler{
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //串行队列
        queue = dispatch_queue_create("XFGDownload_Cancel_Queue", NULL);
    });
    [self.tupleLock lock];
    if (tuples.count<=0) {
        dispatch_async(queue, ^{
            if (completionHandler) {
                completionHandler(nil);
            }
        });
        [self.tupleLock unlock];
        return;
    }
    if (resume) {
        dispatch_group_t group = dispatch_group_create();
        for (XFGDownloadTaskTuple *eachTuple in tuples) {
            [eachTuple.sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                eachTuple.downloadTask.resumeInfoData = resumeData;
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_notify(group, queue, ^{
            if (completionHandler) {
                completionHandler(tuples);
            }
        });
    }else{
        for (XFGDownloadTaskTuple * obj in tuples) {
            [obj.sessionTask cancel];
        }
        dispatch_async(queue, ^{
            if (completionHandler) {
                completionHandler(tuples);
            }
        });
    }
    
    [self.tupleLock unlock];
    
}




@end
