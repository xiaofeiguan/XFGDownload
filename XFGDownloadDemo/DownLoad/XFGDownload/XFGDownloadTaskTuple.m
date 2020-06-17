//
//  XFGDownloadTaskTuple.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadTaskTuple.h"

@implementation XFGDownloadTaskTuple

+ (instancetype)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask sessionTask:(NSURLSessionDownloadTask *)sessionTask
{
    return [[self alloc] initWithDownloadTask:downloadTask sessionTask:sessionTask];
}


- (instancetype)initWithDownloadTask:(XFGDownloadTask *)downloadTask sessionTask:(NSURLSessionDownloadTask *)sessionTask
{
    if (self = [super init]) {
        self.downloadTask = downloadTask;
        self.sessionTask = sessionTask;
    }
    return self;
}


@end
