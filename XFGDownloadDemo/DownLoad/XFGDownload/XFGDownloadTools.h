//
//  XFGDownloadTools.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadTools : NSObject
+ (NSString *)archiverDirectoryPath;
+ (NSString *)archiverFilePathWithIdentifier:(NSString *)identifier;

+ (NSURL *)replacehHomeDirectoryForFileURL:(NSURL *)fileURL;
+ (NSString *)replacehHomeDirectoryForFilePath:(NSString *)filePath;

+ (NSInteger)sizeWithFileURL:(NSURL *)fileURL;
+ (NSError *)removeFileWithFileURL:(NSURL *)fileURL;
@end

NS_ASSUME_NONNULL_END
