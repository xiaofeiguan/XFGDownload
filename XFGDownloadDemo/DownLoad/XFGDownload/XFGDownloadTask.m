//
//  XFGDownloadTask.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadTask.h"

@interface XFGDownloadTask ()
@property(nonatomic,strong) NSURL * realFileUrl;
@end

@implementation XFGDownloadTask
+ (instancetype)taskWithContentURL:(NSURL *)contentURL title:(NSString *)title fileURL:(NSURL *)fileURL
{
    return [[self alloc] initWithContentURL:contentURL title:title fileURL:fileURL];
}

- (instancetype)initWithContentURL:(NSURL *)contentURL title:(NSString *)title fileURL:(NSURL *)fileURL
{
    if (self = [super init]) {
        self.contentURL = contentURL;
        self.title = title;
        self.fileURL = fileURL;
        self.replaceHomeDirectoryIfNeed = YES;
    }
    return self;
}


//序列化
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.object = [aDecoder decodeObjectForKey:@"object"];
        self.state = [[aDecoder decodeObjectForKey:@"state"] unsignedIntegerValue];
        
        self.title = [aDecoder decodeObjectForKey:@"title"];
        self.contentURL = [aDecoder decodeObjectForKey:@"contentURL"];
        self.fileURL = [aDecoder decodeObjectForKey:@"fileURL"];
        self.replaceHomeDirectoryIfNeed = [[aDecoder decodeObjectForKey:@"replaceHomeDirectoryIfNeed"] boolValue];
        
        self.bytesWritten = [[aDecoder decodeObjectForKey:@"bytesWritten"] longLongValue];
        self.totalBytesWritten = [[aDecoder decodeObjectForKey:@"totalBytesWritten"] longLongValue];
        self.totalBytesExpectedToWrite = [[aDecoder decodeObjectForKey:@"totalBytesExpectedToWrite"] longLongValue];
        
        self.resumeInfoData = [aDecoder decodeObjectForKey:@"resumeInfoData"];
        self.resumeFileOffset = [[aDecoder decodeObjectForKey:@"resumeFileOffset"] longLongValue];
        self.resumeExpectedTotalBytes = [[aDecoder decodeObjectForKey:@"resumeExpectedTotalBytes"] longLongValue];
        
        self.error = [aDecoder decodeObjectForKey:@"error"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.object forKey:@"object"];
    [aCoder encodeObject:@(self.state) forKey:@"state"];
    
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.contentURL forKey:@"contentURL"];
    [aCoder encodeObject:self.fileURL forKey:@"fileURL"];
    [aCoder encodeObject:@(self.replaceHomeDirectoryIfNeed) forKey:@"replaceHomeDirectoryIfNeed"];
    
    [aCoder encodeObject:@(self.bytesWritten) forKey:@"bytesWritten"];
    [aCoder encodeObject:@(self.totalBytesWritten) forKey:@"totalBytesWritten"];
    [aCoder encodeObject:@(self.totalBytesExpectedToWrite) forKey:@"totalBytesExpectedToWrite"];
    
    [aCoder encodeObject:self.resumeInfoData forKey:@"resumeInfoData"];
    [aCoder encodeObject:@(self.resumeFileOffset) forKey:@"resumeFileOffset"];
    [aCoder encodeObject:@(self.resumeExpectedTotalBytes) forKey:@"resumeExpectedTotalBytes"];
    
    [aCoder encodeObject:self.error forKey:@"error"];
}


- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[XFGDownloadTask class]]) {
        return NO;
    }
    XFGDownloadTask * task = (XFGDownloadTask *)object;
    if ([self.contentURL.absoluteString isEqualToString:task.contentURL.absoluteString]) {
        return YES;
    }
    return NO;
}


- (void)setBytesWritten:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
}

- (void)setResumeFileOffset:(int64_t)resumeFileOffset resumeExpectedTotalBytes:(int64_t)resumeExpectedTotalBytes{
    
}

@end
