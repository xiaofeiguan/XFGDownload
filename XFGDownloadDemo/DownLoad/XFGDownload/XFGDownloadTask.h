//
//  XFGDownloadTask.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class XFGDownload;
@class XFGDownloadTask;

typedef NS_ENUM(NSUInteger, XFGDownloadTaskState)
{
    XFGDownloadTaskStateNone,
    XFGDownloadTaskStateWaiting,
    XFGDownloadTaskStateRunning,
    XFGDownloadTaskStateSuspend,
    XFGDownloadTaskStateFinished,
    XFGDownloadTaskStateCanceled,
    XFGDownloadTaskStateFailured,
};

@protocol SGDownloadTaskDelegate <NSObject>

@optional
- (void)taskStateDidChange:(XFGDownloadTask *)task;
- (void)taskProgressDidChange:(XFGDownloadTask *)task;

@end

@interface XFGDownloadTask : NSObject
@property (nonatomic, strong) id <NSCoding> object;

@property (nonatomic, weak) XFGDownload * download;
@property (nonatomic, weak) id <SGDownloadTaskDelegate> delegate;

@property (nonatomic, assign) XFGDownloadTaskState state;
@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSURL * fileURL;
@property (nonatomic, assign) BOOL fileDidRemoved;
@property (nonatomic, assign) BOOL fileIsValid;

@property (nonatomic, assign) BOOL replaceHomeDirectoryIfNeed; // default is YES;

@property (nonatomic, assign) float progress;
@property (nonatomic, assign) int64_t bytesWritten;
@property (nonatomic, assign) int64_t totalBytesWritten;
@property (nonatomic, assign) int64_t totalBytesExpectedToWrite;

// about resume
@property (nonatomic, strong) NSData * resumeInfoData;
@property (nonatomic, assign) int64_t resumeFileOffset;
@property (nonatomic, assign) int64_t resumeExpectedTotalBytes;

@property (nonatomic, strong) NSError * error;

//初始化
+ (instancetype)taskWithContentURL:(NSURL *)contentURL
  title:(NSString *)title
fileURL:(NSURL *)fileURL;

- (void)setBytesWritten:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

- (void)setResumeFileOffset:(int64_t)resumeFileOffset resumeExpectedTotalBytes:(int64_t)resumeExpectedTotalBytes;
@end

NS_ASSUME_NONNULL_END
