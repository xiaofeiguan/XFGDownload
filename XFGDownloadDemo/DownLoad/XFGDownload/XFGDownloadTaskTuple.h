//
//  XFGDownloadTaskTuple.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XFGDownloadTask.h"
NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadTaskTuple : NSObject

@property (nonatomic, strong) XFGDownloadTask * downloadTask;
@property (nonatomic, strong) NSURLSessionDownloadTask * sessionTask;

+ (instancetype)tupleWithDownloadTask:(XFGDownloadTask *)downloadTask sessionTask:(NSURLSessionDownloadTask *)sessionTask;
@end

NS_ASSUME_NONNULL_END
