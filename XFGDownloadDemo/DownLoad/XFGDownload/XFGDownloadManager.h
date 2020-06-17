//
//  XFGDownloadManager.h
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XFGDownload.h"
NS_ASSUME_NONNULL_BEGIN

@interface XFGDownloadManager : NSObject
+ (instancetype)sharedInstance;

@property (nonatomic, strong) NSMutableArray <XFGDownload *> * downloads;
@end

NS_ASSUME_NONNULL_END
