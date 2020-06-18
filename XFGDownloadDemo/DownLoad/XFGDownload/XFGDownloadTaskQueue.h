//
//  XFGDownloadTaskQueue.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XFGDownloadTask.h"
#import "XFGDownload.h"
#import "XFGDownloadTools.h"
#import "XFGDownloadManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadTaskQueue : NSObject

@property (nonatomic, weak) XFGDownload * download;

+ (instancetype)queueWithDownload:(XFGDownload *)download;

- (nullable XFGDownloadTask *)taskForContentURL:(NSURL *)contentURL;
- (nullable NSArray <XFGDownloadTask *> *)tasksForAll;
- (nullable NSArray <XFGDownloadTask *> *)tasksForRunning;
- (nullable NSArray <XFGDownloadTask *> *)tasksForRunningOrWatting;
- (nullable NSArray <XFGDownloadTask *> *)tasksForState:(XFGDownloadTaskState)state;

- (void)setTaskStateWithTask:(XFGDownloadTask *)task state:(XFGDownloadTaskState)state;

- (nullable XFGDownloadTask *)downloadTaskSync;
- (void)addDownloadTask:(XFGDownloadTask *)task;
- (void)addDownloadTasks:(NSArray <XFGDownloadTask *> *)tasks;

- (void)addSuppendTask:(XFGDownloadTask *)task;
- (void)addSuppendTasks:(NSArray <XFGDownloadTask *> *)tasks;

- (void)resumeAllTasks;
- (void)resumeTask:(XFGDownloadTask *)task;
- (void)resumeTasks:(NSArray <XFGDownloadTask *> *)tasks;

- (void)suspendAllTasks;
- (void)suspendTask:(XFGDownloadTask *)task;
- (void)suspendTasks:(NSArray <XFGDownloadTask *> *)tasks;

- (void)cancelAllTasks;
- (void)cancelTask:(XFGDownloadTask *)task;
- (void)cancelTasks:(NSArray <XFGDownloadTask *> *)tasks;

- (void)deleteAllTaskFiles;
- (void)deleteTaskFile:(XFGDownloadTask *)task;
- (void)deleteTaskFiles:(NSArray <XFGDownloadTask *> *)tasks;

- (void)invalidate;
- (void)archive;

@end

NS_ASSUME_NONNULL_END
