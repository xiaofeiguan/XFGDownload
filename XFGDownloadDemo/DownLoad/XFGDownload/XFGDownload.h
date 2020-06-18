//
//  XFGDownload.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XFGDownloadManager.h"
#import "XFGDownloadTaskRule.h"
#import "XFGDownloadTaskQueue.h"
#import "XFGDownloadTaskTuple.h"
#import "XFGDownloadTupleQueue.h"
#import "XFGDownloadTools.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN

@protocol XFGDownloadDelegate <NSObject>

@optional;
- (void)downloadDidCompleteAllRunningTasks:(XFGDownload *)download;      // maybe finished, canceled and failured.
- (void)download:(XFGDownload *)download taskStateDidChange:(XFGDownloadTask *)task;
- (void)download:(XFGDownload *)download taskProgressDidChange:(XFGDownloadTask *)task;

@end

@interface XFGDownload : NSObject

@property (nonatomic, copy, readonly) NSString * identifier;
@property (nonatomic, strong, readonly) NSURLSessionConfiguration * sessionConfiguration;

@property (nonatomic, weak) id<XFGDownloadDelegate> delegate;

@property (nonatomic, assign) NSUInteger maxConcurrentOperationCount; // defalut is 1.

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)download;    // default download manager.
+ (instancetype)downloadWithIdentifier:(NSString *)identifier;

- (void)run;
- (void)invalidate;         // async is YES.
- (void)invalidateAsync:(BOOL)async;


- (nullable XFGDownloadTask *)taskForContentURL:(NSURL *)contentURL;
- (nullable NSArray <XFGDownloadTask *> *)tasksForAll;
- (nullable NSArray <XFGDownloadTask *> *)tasksForRunningOrWatting;
- (nullable NSArray <XFGDownloadTask *> *)tasksForState:(XFGDownloadTaskState)state;


-(void)addTaskWithContentURL:(NSURL*)contentURL title:(NSString*)title fileURL:(NSURL*)fileURL;


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

- (void)cancelAllTasksAndDeleteFiles;
- (void)cancelTaskAndDeleteFile:(XFGDownloadTask *)task;
- (void)cancelTasksAndDeleteFiles:(NSArray <XFGDownloadTask *> *)tasks;


#if TARGET_OS_IOS
/**
 *  Must be called when the AppDelegate receives the following callback.
 *
 *  - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
 */
+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
#endif

@end

NS_ASSUME_NONNULL_END
