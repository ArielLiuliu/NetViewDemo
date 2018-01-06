//
//  NetView.m
//  NetViewDemo
//
//  Created by lx on 2018/1/6.
//  Copyright © 2018年 lx. All rights reserved.
//

#import "NetView.h"

//定义文件管理对象
#define FM [NSFileManager defaultManager]

//web缓存路径
#define Cache NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]

//图片缓存路径
#define ImageCache [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"imageCache"]

@interface NetView ()<NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) UIActivityIndicatorView *iView;
@end

@implementation NetView




/**
 @功能：根据URL获取网络图片
 @参数：图片url  默认显示图片
 @返回值：空
 */
- (void)setImageURL:(NSString*)strURL placeholderImage:(UIImage*)placeholderImage {
    [self show:NO];//不显示进度条
    
    self.flag = YES;
    NSString *type = [[strURL componentsSeparatedByString:@"."] lastObject];
    if ([type isEqualToString:@"gif"]) {
        self.flag = NO;
    }
    [self addView];//添加相应类型子视图
    
    if (!strURL || strURL.length == 0) {
        self.imaView.image = placeholderImage;
        return;
    }
    
    //图片处理
    UIImage *image = [UIImage imageWithContentsOfFile:[self filePath:strURL]];//本地有，则显示
    if (image) {
        if (self.flag) {
            self.imaView.image = image;
        }
        else
        {
            self.imaView.image = [YLGIFImage imageWithContentsOfFile:[self filePath:strURL]];
        }
        
        //向外界通知缓存大小
        if (self.delegate && [self.delegate respondsToSelector:@selector(showCacheSize:)]) {
            [self.delegate showCacheSize:[NetView imageCacheSize]];
        }
    } else {
        self.imaView.image = placeholderImage;//显示默认图片
        [self show:YES];//显示进度条
        NSURL *url = [NSURL URLWithString:[strURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
        [self.downloadTask cancel];
        self.downloadTask = nil;
        self.downloadTask = [session downloadTaskWithURL:url];
        [self.downloadTask resume];//启动
    }
}

//添加相应类型子视图
- (void)addView
{
    
    if (self.flag) {
        self.imaView = [[UIImageView alloc] initWithFrame:self.bounds];
    }
    else{
        self.imaView = [[YLImageView alloc]initWithFrame:self.bounds];
    }
    [self addSubview:self.imaView];
}

//取消当前图片请求
- (void)cancel {
    [self show:NO];//不显示等待视图
    if (self.downloadTask) {
        [self.downloadTask cancel];
        self.downloadTask = nil;
    }
}

//获取本地图片缓存数据大小
+ (NSString*)imageCacheSize {
    NSString *size = nil;
    
    //获取图片缓存大小
    NSArray *contents = [FM contentsOfDirectoryAtPath:ImageCache error:nil];
    unsigned long long fileSize = 0;//保存文件总大小
    for (NSString *file in contents) {
        NSString *filePath = [ImageCache stringByAppendingPathComponent:file];
        fileSize += [[FM attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    
    //获取离线web缓存路径
    NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
    NSString *fsCachedData = [NSString stringWithFormat:@"%@/%@/fsCachedData",Cache,identifier];
    
    //获取离线web缓存大小
    contents = [FM contentsOfDirectoryAtPath:fsCachedData error:nil];
    for (NSString *file in contents) {
        NSString *filePath = [fsCachedData stringByAppendingPathComponent:file];
        fileSize += [[FM attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    
    if (fileSize <= 0) {
        size = @"0M";
    }
    else if (fileSize < 1024) {
        //获取多少K(小于1k)
        double num = (fileSize%1024)/100;
        size = [NSString stringWithFormat:@"%.1fK", num];
    }
    else if (fileSize < 1024*1024) {
        //获取多少K(大于1k)
        unsigned long long num = fileSize/1024;
        double num2 = (fileSize-num*1024)%1024/100;
        size = [NSString stringWithFormat:@"%.1fK", (num+num2)];
    }
    else if (fileSize < 1024*1024*1024) {
        //获取多少M
        unsigned long long num = fileSize/(1024*1024);
        size = [NSString stringWithFormat:@"%.lldM", num];
    } else {
        //获取多少G
        unsigned long long num = fileSize/(1024*1024*1024);
        size = [NSString stringWithFormat:@"%.lldG", num];
    }
    
    return size;
}

//清理所有的图片缓存
+ (void)clearAllCaches {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //清理所有缓存图片
        [FM removeItemAtPath:ImageCache error:nil];
        
        //清理所有网页离线缓存
        NSString *identifier = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];//获取当前应用程序identifier
        //获取离线web缓存路径
        NSString *fsCachedData = [NSString stringWithFormat:@"%@/%@/fsCachedData",Cache,identifier];
        NSArray* contents = [FM contentsOfDirectoryAtPath:fsCachedData error:nil];
        for (NSString *file in contents) {
            NSString *filePath = [fsCachedData stringByAppendingPathComponent:file];
            [FM removeItemAtPath:filePath error:nil];
        }
    });
}

//显示下载进度
- (void)show:(BOOL)flag {
    if (flag) {
        if (!self.iView) {
            self.iView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.iView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
            self.iView.color = [UIColor orangeColor];
            [self addSubview:self.iView];
        }
        
        [self.iView startAnimating];
    } else {
        [self.iView stopAnimating];
    }
}

//获取图片完整缓存路径
- (NSString*)filePath:(NSString*)url {
    if (url) {
        BOOL directory = YES;
        if (![FM fileExistsAtPath:ImageCache isDirectory:&directory]) {
            [FM createDirectoryAtPath:ImageCache withIntermediateDirectories:NO attributes:nil error:nil];//创建图片缓存文件夹
        }
        
        NSArray *ary = [url componentsSeparatedByString:@"/"];
        NSString *fileName = [ary lastObject];
        NSString *fPath = [ImageCache stringByAppendingPathComponent:fileName];
        return fPath;
    }
    
    return nil;
}

#pragma mark - NSURLSessionDownloadDelegate
//下载完成调用
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    //location还是一个临时路径,需要挪到自己的路径里
    NSString *url = downloadTask.response.URL.absoluteString;
    NSString *fPath = [self filePath:url];
    [FM removeItemAtPath:fPath error:nil];//如果有，则先移旧的
    [FM moveItemAtURL:location toURL:[NSURL fileURLWithPath:fPath] error:nil];
}

//任务完成调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{//主线程显示
        [self show:NO];//隐藏进度条
        NSString *url = task.response.URL.absoluteString;
        if (!error) {
            if (self.flag) {
                self.imaView.image=[UIImage imageWithContentsOfFile:[self filePath:url]];//本地有，则显示
            }
            else
            {
                self.imaView.image = [YLGIFImage imageWithContentsOfFile:[self filePath:url]];
            }
            
        } else {
            self.imaView.image=[UIImage imageNamed:@"defaultimg"];//恢复默认图片
        }
        
        //向外界通知缓存大小
        if (self.delegate && [self.delegate respondsToSelector:@selector(showCacheSize:)]) {
            [self.delegate showCacheSize:[NetView imageCacheSize]];
        }
    });
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
