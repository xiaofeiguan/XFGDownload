//
//  LGHDwonloadTaskController.m
//  DownLoad
//
//  Created by 小肥观 on 2020/6/16.
//  Copyright © 2020 share. All rights reserved.
//

#import "LGHDwonloadTaskController.h"
#import "VideoTableViewCell.h"
@interface LGHDwonloadTaskController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView * mainTableView;
@end

@implementation LGHDwonloadTaskController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mainTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.mainTableView.delegate = self;
    self.mainTableView.dataSource = self;
    [self.view addSubview:self.mainTableView];
    [self.mainTableView reloadData];
}


-(void)updateDatas{
    [self.mainTableView reloadData];
}

#pragma mark - UITableViewDelegate/UITableViewDatasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoTableViewCellIdentify"];
    
    if (!cell) {
        cell = (VideoTableViewCell*)[[UINib nibWithNibName:@"VideoTableViewCell" bundle:nil]instantiateWithOwner:self options:nil].firstObject;
    }
    
    cell.titleLabel.text = @"1.mp4";
    cell.speedLabel.text = @"230kb/s";
    cell.progressLabel.text = [NSString stringWithFormat:@"%lf/%lf",1.0,2.0];
    cell.progressView.progress = 0.5;
    
    return cell;
}




-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 115;
}

@end
