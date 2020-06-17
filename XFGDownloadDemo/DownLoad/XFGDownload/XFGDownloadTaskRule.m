//
//  XFGDownloadTaskRule.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadTaskRule.h"

@implementation XFGDownloadTaskRule
+ (NSURLSessionDownloadTask *)downloadTaskWithSession:(NSURLSession *)session resumeData:(NSData *)resumeData{
    
    return  [session downloadTaskWithResumeData:resumeData];
}
@end
