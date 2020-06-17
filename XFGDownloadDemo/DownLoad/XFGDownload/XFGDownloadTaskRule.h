//
//  XFGDownloadTaskRule.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadTaskRule : NSObject
+ (NSURLSessionDownloadTask *)downloadTaskWithSession:(NSURLSession *)session resumeData:(NSData *)resumeData;
@end

NS_ASSUME_NONNULL_END
