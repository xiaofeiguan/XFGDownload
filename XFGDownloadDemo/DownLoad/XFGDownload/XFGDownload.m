//
//  XFGDownload.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownload.h"

NSString * const XFGDownloadDefaultIdentifier = @"XFGDownloadDefaultIdentifier";

@interface XFGDownload () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession * session;
@property (nonatomic, strong) NSOperationQueue * sessionDelegateQueue;
@property (nonatomic, copy) void(^backgroundCompletionHandler)(void);

@property (nonatomic, strong) XFGDownloadTaskQueue * taskQueue;
@property (nonatomic, strong) XFGDownloadTupleQueue * taskTupleQueue;
@property (nonatomic, strong) NSCondition * concurrentCondition;
@property (nonatomic, strong) NSLock * lastResumeLock;
@property (nonatomic, strong) NSCondition * invalidateConditaion;

@property (nonatomic, strong) NSOperationQueue * downloadOperationQueue;
@property (nonatomic, strong) NSInvocationOperation * downloadOperation;

@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL closed;
@end

@implementation XFGDownload

#pragma mark - init
+ (instancetype)download
{
    return [self downloadWithIdentifier:XFGDownloadDefaultIdentifier];
}

+ (instancetype)downloadWithIdentifier:(NSString *)identifier
{
    for (XFGDownload * obj in [XFGDownloadManager sharedInstance].downloads) {
        if ([obj.identifier isEqualToString:identifier]) {
            return obj;
        }
    }
    //不同的界面需要不同的 XFGDownLoad
    XFGDownload * obj = [[self alloc] initWithIdentifier:identifier];
    [[XFGDownloadManager sharedInstance].downloads addObject:obj];
    return obj;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        //标识
        self->_identifier = identifier;
        //__NSURLBackroungSession;
        self->_sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        self.maxConcurrentOperationCount = 1;
        //任务队列（所有的任务队列：下载中，等待下载，暂停，取消，失败，以及完成）
        self.taskQueue = [XFGDownloadTaskQueue queueWithDownload:self];
        //元组队列(当前下载中的任务)
        self.taskTupleQueue = [[XFGDownloadTupleQueue alloc] init];
    }
    return self;
}


/**
 * 添加下载任务到队列
 */
-(void)addTaskWithContentURL:(NSURL*)contentURL title:(NSString*)title fileURL:(NSURL*)fileURL{
    XFGDownloadTask *task = [self taskForContentURL:contentURL];
    if (!task) {
        task = [XFGDownloadTask taskWithContentURL:contentURL title:title fileURL:fileURL];
    }
    //添加到队列
    [self addDownloadTask:task];
}


#pragma  mark - run
- (void)run
{
    if (!self.running) {
        self.running = YES;
        [self setupOperation];
    }
}
// 非常重要
-(void)setupOperation{
    if (self.maxConcurrentOperationCount <= 0) {
        self.maxConcurrentOperationCount = 1; //默认并发下载量为1
    }
    //初始化并发条件锁
    self.concurrentCondition = [[NSCondition alloc] init];
    self.lastResumeLock = [[NSLock alloc] init];
    //回调队列，异步串行队列,代理回调 //NSOperationQueue
    self.sessionDelegateQueue = [[NSOperationQueue alloc] init];
    self.sessionDelegateQueue.maxConcurrentOperationCount = 1;
    //最高优先级，主要用于提供交互UI的操作，比如处理点击事件，绘制图像到屏幕上
    self.sessionDelegateQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.sessionDelegateQueue.suspended = YES;
    // __NSURLBackgroundSession
    self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.sessionDelegateQueue];
    // 获取后台的下载任务
    Ivar ivar = class_getInstanceVariable(NSClassFromString(@"__NSURLBackgroundSession"), "_tasks");
    if (ivar) {
        NSDictionary <NSNumber *, NSURLSessionDownloadTask *> * lastTasks = object_getIvar(self.session, ivar);
        if (lastTasks && lastTasks.count > 0) {
            for (NSNumber * key in lastTasks) {
                //NSURLSession下载任务
                NSURLSessionDownloadTask * obj = [lastTasks objectForKey:key];
                //创建 downloadTask，是的，做了缓存
                XFGDownloadTask * downloadTask = [self.taskQueue taskForContentURL:[self getURLFromSessionTask:obj]];
                if (downloadTask) {
                    //改变状态
                    [self.taskQueue setTaskStateWithTask:downloadTask state:XFGDownloadTaskStateRunning];
                    XFGDownloadTaskTuple * tuple = [XFGDownloadTaskTuple tupleWithDownloadTask:downloadTask sessionTask:obj];
                    [self.taskTupleQueue addTuple:tuple];
                }
            }
        }
    }
    [self.lastResumeLock unlock];
    self.sessionDelegateQueue.suspended = NO;
    // 创建了一个下载任务 NSInvocationOperation
    self.downloadOperation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(downloadOperationHandler) object:nil];
    //创建下载队列
    self.downloadOperationQueue = [[NSOperationQueue alloc]init];
    
    self.downloadOperationQueue.maxConcurrentOperationCount = 1;
    
    self.downloadOperationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    
    [self.downloadOperationQueue addOperation:self.downloadOperation];
}

// 高能来了，关键中的关键
-(void)downloadOperationHandler{
    //常驻线程，阻塞、执行、等待（self.concurrentCondition，条件锁的检测）
    //消费者的角色 -- downLoadTask
    while(YES){
        @autoreleasepool { //线程池
            if (self.closed) {
                break;
            }
            NSLog(@"current Thread -- %@",[NSThread currentThread]);
            //条件加锁
            [self.concurrentCondition lock];
            // 超过最大并发数时,阻塞掉了.
            while (self.taskTupleQueue.tuples.count >= self.maxConcurrentOperationCount) {
                [self.concurrentCondition wait];
            }
            [self.concurrentCondition unlock];
            //同步获取下载任务 downloadTask
            XFGDownloadTask * downloadTask = [self.taskQueue downloadTaskSync];
            if (!downloadTask) {
                break;
            }
            [self.taskQueue setTaskStateWithTask:downloadTask state:XFGDownloadTaskStateRunning];
            // 获取NSURLSessionDownloadTask
            NSURLSessionDownloadTask *sessionTask = nil;
            if(downloadTask.resumeInfoData.length>0){
                sessionTask  = [XFGDownloadTaskRule downloadTaskWithSession:self.session resumeData:downloadTask.resumeInfoData];
            }else{
                sessionTask = [self.session downloadTaskWithURL:downloadTask.contentURL];
            }
            XFGDownloadTaskTuple *tuple = [XFGDownloadTaskTuple tupleWithDownloadTask:downloadTask sessionTask:sessionTask];
            [self.taskTupleQueue addTuple:tuple];
            [sessionTask resume];
            
        }
    }
}




#pragma mark - Tools
- (NSURL *)getURLFromSessionTask:(NSURLSessionTask *)sessionTask
{
    if (sessionTask.originalRequest.URL) {
        return sessionTask.originalRequest.URL;
    } else if (sessionTask.currentRequest.URL) {
        return sessionTask.currentRequest.URL;
    }
    return nil;
}

#pragma mark - Interface

- (XFGDownloadTask *)taskForContentURL:(NSURL *)contentURL
{
    return [self.taskQueue taskForContentURL:contentURL];
}

- (NSArray <XFGDownloadTask *> *)tasksForAll
{
    return [self.taskQueue.tasksForAll copy];
}

- (NSArray <XFGDownloadTask *> *)tasksForRunningOrWatting
{
    return [[self.taskQueue tasksForRunningOrWatting] copy];
}

- (NSArray <XFGDownloadTask *> *)tasksForState:(XFGDownloadTaskState)state
{
    return [[self.taskQueue tasksForState:state] copy];
}

- (void)addDownloadTask:(XFGDownloadTask *)task
{
    [self.taskQueue addDownloadTask:task];
}

- (void)addDownloadTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue addDownloadTasks:tasks];
}

- (void)addSuppendTask:(XFGDownloadTask *)task
{
    [self.taskQueue addSuppendTask:task];
}

- (void)addSuppendTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue addSuppendTasks:tasks];
}

- (void)resumeAllTasks
{
    [self.taskQueue resumeAllTasks];
}

- (void)resumeTask:(XFGDownloadTask *)task
{
    [self.taskQueue resumeTask:task];
}

- (void)resumeTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue resumeTasks:tasks];
}

- (void)suspendAllTasks
{
    [self.taskQueue suspendAllTasks];
    [self.taskTupleQueue cancelAllTupleResume:YES completionHandler:nil];
}

- (void)suspendTask:(XFGDownloadTask *)task
{
    [self.taskQueue suspendTask:task];
    [self.taskTupleQueue cancelDownloadTask:task resume:YES completionHandler:nil];
}

- (void)suspendTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue suspendTasks:tasks];
    [self.lastResumeLock lock];
    [self.taskTupleQueue cancelDownloadTasks:tasks resume:YES completionHandler:^(NSArray<XFGDownloadTaskTuple *> *tuples) {
        [self.lastResumeLock unlock];
    }];
}

- (void)cancelAllTasks
{
    [self.taskQueue cancelAllTasks];
    [self.taskTupleQueue cancelAllTupleResume:NO completionHandler:nil];
}

- (void)cancelTask:(XFGDownloadTask *)task
{
    [self.taskQueue cancelTask:task];
    [self.taskTupleQueue cancelDownloadTask:task resume:NO completionHandler:nil];
}

- (void)cancelTasks:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue cancelTasks:tasks];
    [self.taskTupleQueue cancelDownloadTasks:tasks resume:NO completionHandler:nil];
}

- (void)cancelAllTasksAndDeleteFiles
{
    [self.taskQueue deleteAllTaskFiles];
    [self cancelAllTasks];
}

- (void)cancelTaskAndDeleteFile:(XFGDownloadTask *)task
{
    [self.taskQueue deleteTaskFile:task];
    [self cancelTask:task];
}

- (void)cancelTasksAndDeleteFiles:(NSArray <XFGDownloadTask *> *)tasks
{
    [self.taskQueue cancelTasks:tasks];
    [self cancelTasks:tasks];
}

#pragma mark - 后台回调
+(void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    XFGDownload *download = [XFGDownload downloadWithIdentifier:identifier];
    download.backgroundCompletionHandler = completionHandler;
}

#pragma mark - NSURLSessionDownloadDelegate


/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 
 *  进入后台时的回调。
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    if (self.backgroundCompletionHandler) {
        self.backgroundCompletionHandler();
    }
    
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 *
 */
/**下载任务相关的最后一条消息发送。**/
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    //对象锁先加锁，downloadTask数据是线程安全的
    //确保数据的
    [self.lastResumeLock lock];
    //条件锁加锁
    [self.concurrentCondition lock];
    XFGDownloadTask * downloadTask = [self.taskQueue taskForContentURL:[self getURLFromSessionTask:task]];
    XFGDownloadTaskTuple * tuple = [self.taskTupleQueue tupleWithDownloadTask:downloadTask sessionTask:(NSURLSessionDownloadTask *)task];
    if (!tuple) {
        [self.taskTupleQueue removeTupleWithSesstionTask:task];
        //signal -- 唤醒当前线程，当前正在等待的任务继续执行
        [self.concurrentCondition signal];
        [self.concurrentCondition unlock];
        [self.lastResumeLock unlock];
        return;
    }
    XFGDownloadTaskState state;
    if (error) {
        NSData * resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            tuple.downloadTask.resumeInfoData = resumeData;
        }
        if (error.code == NSURLErrorCancelled) {
            state = XFGDownloadTaskStateSuspend;
        } else {
            tuple.downloadTask.error = error;
            state = XFGDownloadTaskStateFailured;
        }
    }else{
        if (![[NSFileManager defaultManager] fileExistsAtPath:tuple.downloadTask.fileURL.path]) {
            tuple.downloadTask.error = [NSError errorWithDomain:@"download file is deleted" code:-1 userInfo:nil];
            state = XFGDownloadTaskStateFailured;
        } else {
            state = XFGDownloadTaskStateFinished;
        }
    }
    [self.taskQueue setTaskStateWithTask:tuple.downloadTask state:state];
    [self.taskTupleQueue removeTuple:tuple];
    if ([self.taskQueue tasksForRunningOrWatting].count <= 0 && self.taskTupleQueue.tuples.count <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(downloadDidCompleteAllRunningTasks:)]) {
                [self.delegate downloadDidCompleteAllRunningTasks:self];
            }
        });
    }
    [self.concurrentCondition signal];
    [self.concurrentCondition unlock];
    [self.lastResumeLock unlock];
}

/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
/**当下载任务完成下载时发送。*/
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)sessionDownloadTask
didFinishDownloadingToURL:(NSURL *)location{
    [self.lastResumeLock lock];
    XFGDownloadTask * xfgTask = [self.taskQueue taskForContentURL:[self getURLFromSessionTask:sessionDownloadTask]];
    XFGDownloadTaskTuple * tuple = [self.taskTupleQueue tupleWithDownloadTask:xfgTask sessionTask:sessionDownloadTask];
    if (!tuple) {
        [self.lastResumeLock unlock];
        return;
    }
    
    NSString * path = location.path;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exists) {
        path = [XFGDownloadTools replacehHomeDirectoryForFilePath:path];
        exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
        if (!exists) {
            tuple.downloadTask.error = [NSError errorWithDomain:@"download file is deleted" code:-1 userInfo:nil];
            [self.lastResumeLock unlock];
            return;
        }
    }
    
    NSError * error = nil;
    unsigned long long fileSzie = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error] fileSize];
    if (error || fileSzie == 0) {
        tuple.downloadTask.error = [NSError errorWithDomain:@"download file is empty" code:-1 userInfo:nil];
        [self.lastResumeLock unlock];
        return;
    }
    
    NSString * filePath = tuple.downloadTask.fileURL.path;
    NSString * directoryPath = filePath.stringByDeletingLastPathComponent;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    BOOL isDirectory;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDirectory];
    if (!result || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [[NSFileManager defaultManager] moveItemAtPath:path toPath:filePath error:&error];
    tuple.downloadTask.error = error;
    [self.lastResumeLock unlock];
}

/* Sent periodically to notify the delegate of download progress. */
/**定期发送下载进度。*/
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    [self.lastResumeLock lock];
    XFGDownloadTask *xfgTask = [self.taskQueue taskForContentURL:[self getURLFromSessionTask:downloadTask]];
    XFGDownloadTaskTuple *tuple = [self.taskTupleQueue tupleWithDownloadTask:xfgTask sessionTask:downloadTask];
    if (!tuple) {
        [self.lastResumeLock unlock];
        return;
    }
    
    // 协议回调
    [tuple.downloadTask setBytesWritten:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    if ([self.delegate respondsToSelector:@selector(download:taskProgressDidChange:)]) {
        [self.delegate download:self taskProgressDidChange:xfgTask];
    }
    if (tuple.downloadTask.state != XFGDownloadTaskStateSuspend) {
        [self.taskQueue setTaskStateWithTask:tuple.downloadTask state:XFGDownloadTaskStateRunning];
    }
    [self.concurrentCondition unlock];
    
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */
// 当下载恢复时发送回调
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
    [self.lastResumeLock lock];
    XFGDownloadTask *xfgTask = [self.taskQueue taskForContentURL:[self getURLFromSessionTask:downloadTask]];
    XFGDownloadTaskTuple *tuple = [self.taskTupleQueue tupleWithDownloadTask:xfgTask sessionTask:downloadTask];
    if (!tuple) {
        [self.lastResumeLock unlock];
        return;
    }
    tuple.downloadTask.resumeFileOffset = fileOffset;
    tuple.downloadTask.resumeExpectedTotalBytes = expectedTotalBytes;
    if (tuple.downloadTask.state != XFGDownloadTaskStateSuspend) {
        [self.taskQueue setTaskStateWithTask:tuple.downloadTask state:XFGDownloadTaskStateRunning];
    }
    [self.lastResumeLock unlock];
    
}

#pragma mark - invalidate
- (void)invalidate
{
    [self invalidateAsync:YES];
}

- (void)invalidateAsync:(BOOL)async
{
    if (self.closed) return;
    
    self.closed = YES;
    [self.taskQueue invalidate];
    [self.taskTupleQueue cancelAllTupleResume:YES completionHandler:^(NSArray <XFGDownloadTaskTuple *> * tuples) {
        //归档当前 TaskQueue
        [self.taskQueue archive];
        [self.session invalidateAndCancel];
        [self.downloadOperationQueue cancelAllOperations];
        self.downloadOperation = nil;
        [self.concurrentCondition lock];
        [self.concurrentCondition broadcast];
        [self.concurrentCondition unlock];
        [[XFGDownloadManager sharedInstance].downloads removeObject:self];
        [self.invalidateConditaion lock];
        [self.invalidateConditaion broadcast];
        [self.invalidateConditaion unlock];
    }];
    if (!async) {
        if (!self.invalidateConditaion) {
            self.invalidateConditaion = [[NSCondition alloc] init];
        }
        [self.invalidateConditaion lock];
        [self.invalidateConditaion wait];
        [self.invalidateConditaion unlock];
    }
}

#pragma  mark - dealloc
- (void)dealloc
{
    [self invalidate];
}



@end
