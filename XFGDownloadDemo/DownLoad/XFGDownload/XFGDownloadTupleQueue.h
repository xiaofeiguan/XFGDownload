//
//  XFGDownloadTupleQueue.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XFGDownloadTaskTuple.h"
NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadTupleQueue : NSObject
@property (nonatomic, strong, readonly) NSMutableArray * tuples;


- (XFGDownloadTaskTuple *)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask;
- (NSArray <XFGDownloadTaskTuple *> *)tuplesWithDownloadTasks:(NSArray <XFGDownloadTask *> *)downloadTasks;

- (XFGDownloadTaskTuple *)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask sessionTask:(NSURLSessionDownloadTask *)sessionTask;

- (void)addTuple:(XFGDownloadTaskTuple *)tuple;

- (void)removeTupleWithSesstionTask:(NSURLSessionTask *)sessionTask;
- (void)removeTuple:(XFGDownloadTaskTuple *)tuple;
- (void)removeTuples:(NSArray <XFGDownloadTaskTuple *> *)tuples;

- (void)cancelDownloadTask:(XFGDownloadTask *)downloadTask resume:(BOOL)resume completionHandler:(void(^)(XFGDownloadTaskTuple * tuple))completionHandler;

- (void)cancelDownloadTasks:(NSArray <XFGDownloadTask *> *)downloadTasks resume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler;

- (void)cancelAllTupleResume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler;

- (void)cancelTuple:(XFGDownloadTaskTuple *)tuple resume:(BOOL)resume completionHandler:(void(^)(XFGDownloadTaskTuple * tuple))completionHandler;

- (void)cancelTuples:(NSArray <XFGDownloadTaskTuple *> *)tuples resume:(BOOL)resume completionHandler:(void(^)(NSArray <XFGDownloadTaskTuple *> * tuples))completionHandler;

@end

NS_ASSUME_NONNULL_END
