//
//  XFGDownloadManager.m
//  DownLoad
//
//  Created by 刘观华 on 2020/6/17.
//  Copyright © 2020 share. All rights reserved.
//

#import "XFGDownloadManager.h"
#import "XFGDownload.h"
#import <UIKit/UIKit.h>

@implementation XFGDownloadManager

+(instancetype)sharedInstance{
    static XFGDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[XFGDownloadManager alloc]init];
    });
    return manager;
}

-(instancetype)init{
    if (self = [super init]) {
        self.downloads = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}


#pragma mark - NSNotification
-(void)applicationWillTerminate{
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

@end
