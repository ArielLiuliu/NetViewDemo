//
//  NetView.h
//  NetViewDemo
//
//  Created by lx on 2018/1/6.
//  Copyright © 2018年 lx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YLGIFImage.h"
#import "YLImageView.h"

@protocol NetViewDelegate <NSObject>

@optional
- (void)showCacheSize:(NSString*)size;//向外界通知缓存大小

@end


@interface NetView : UIView

@property (nonatomic) BOOL flag;//flag：图片类型； NO表示gif

@property (nonatomic,retain) UIImageView *imaView;

@property (nonatomic, assign) id<NetViewDelegate> delegate;




/**
 @功能：根据URL获取网络图片
 @参数：图片url  默认显示图片
 @返回值：空
 */
- (void)setImageURL:(NSString*)strURL placeholderImage:(UIImage*)placeholderImage;

//取消当前图片请求
- (void)cancel;

//清理所有的图片缓存
+ (void)clearAllCaches;

//获取本地图片缓存数据大小
+ (NSString*)imageCacheSize;

@end



