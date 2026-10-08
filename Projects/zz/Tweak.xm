#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ================= 全局 UI 管理器 (转转版) =================
@interface RadarManager : NSObject
@property (nonatomic, strong) UIView *floatingView;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, assign) BOOL isRadarActive;
@property (nonatomic, assign) NSInteger hitCount;
+ (instancetype)sharedManager;
- (void)showFloatingUI;
- (void)logMessage:(NSString *)msg;
@end

@implementation RadarManager

+ (instancetype)sharedManager {
    static RadarManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RadarManager alloc] init];
        instance.isRadarActive = NO;
        instance.hitCount = 0;
    });
    return instance;
}

- (void)showFloatingUI {
    if (self.floatingView) return;
    
    UIWindow *keyWindow = nil;
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            keyWindow = scene.windows.firstObject;
            break;
        }
    }
    if (!keyWindow) return;
    
    // 1. 主面板
    self.floatingView = [[UIView alloc] initWithFrame:CGRectMake(10, 100, 320, 450)];
    self.floatingView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    self.floatingView.layer.cornerRadius = 12;
    self.floatingView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingView.layer.shadowOpacity = 0.2;
    self.floatingView.layer.shadowOffset = CGSizeMake(0, 4);
    self.floatingView.layer.shadowRadius = 8;
    
    // 2. 标题栏
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 200, 20)];
    titleLabel.text = @"🚀 转转天命雷达助手";
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.floatingView addSubview:titleLabel];
    
    // 3. 标签
    NSArray *tags = @[@"转转专版", @"17.0-17.3.1", @"静默拦截"];
    CGFloat tagX = 15;
    for (NSString *tag in tags) {
        UILabel *tagL = [[UILabel alloc] initWithFrame:CGRectMake(tagX, 45, 85, 22)];
        tagL.text = tag;
        tagL.font = [UIFont systemFontOfSize:10];
        tagL.textColor = [UIColor orangeColor];
        tagL.layer.borderColor = [UIColor orangeColor].CGColor;
        tagL.layer.borderWidth = 0.5;
        tagL.layer.cornerRadius = 4;
        tagL.textAlignment = NSTextAlignmentCenter;
        [self.floatingView addSubview:tagL];
        tagX += 90;
    }
    
    // 4. 控制按钮
    UIButton *toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    toggleBtn.frame = CGRectMake(15, 75, 90, 30);
    toggleBtn.backgroundColor = [UIColor systemBlueColor];
    toggleBtn.layer.cornerRadius = 6;
    toggleBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [toggleBtn setTitle:@"开始提取" forState:UIControlStateNormal];
    [toggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toggleBtn addTarget:self action:@selector(toggleRadar:) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:toggleBtn];
    
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(115, 75, 90, 30);
    clearBtn.backgroundColor = [UIColor systemGrayColor];
    clearBtn.layer.cornerRadius = 6;
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [clearBtn setTitle:@"清除列表" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearLogs) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:clearBtn];
    
    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    copyBtn.frame = CGRectMake(215, 75, 90, 30);
    copyBtn.backgroundColor = [UIColor systemOrangeColor];
    copyBtn.layer.cornerRadius = 6;
    copyBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [copyBtn setTitle:@"复制全部内容" forState:UIControlStateNormal];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [copyBtn addTarget:self action:@selector(copyLogs) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:copyBtn];
    
    // 5. 日志文本框
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 115, 290, 320)];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.logTextView.layer.cornerRadius = 6;
    self.logTextView.font = [UIFont systemFontOfSize:12];
    self.logTextView.textColor = [UIColor darkGrayColor];
    [self.floatingView addSubview:self.logTextView];
    
    // 6. 拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.floatingView addGestureRecognizer:pan];
    
    [keyWindow addSubview:self.floatingView];
}

- (void)toggleRadar:(UIButton *)sender {
    self.isRadarActive = !self.isRadarActive;
    if (self.isRadarActive) {
        [sender setTitle:@"暂停提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemRedColor];
    } else {
        [sender setTitle:@"开始提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemBlueColor];
    }
}

- (void)clearLogs {
    self.logTextView.text = @"";
    self.hitCount = 0;
}

- (void)copyLogs {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.logTextView.text;
    
    UIWindow *keyWindow = self.floatingView.window;
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 40)];
    toast.center = CGPointMake(keyWindow.bounds.size.width/2, keyWindow.bounds.size.height/2);
    toast.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.text = @"复制成功";
    toast.layer.cornerRadius = 20;
    toast.clipsToBounds = YES;
    [keyWindow addSubview:toast];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast removeFromSuperview];
    });
}

- (void)logMessage:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hitCount += 1;
        NSString *newLog = [NSString stringWithFormat:@"%ld. %@\n\n", (long)self.hitCount, msg];
        self.logTextView.text = [self.logTextView.text stringByAppendingString:newLog];
        
        NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
        [self.logTextView scrollRangeToVisible:range];
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.floatingView.superview];
    self.floatingView.center = CGPointMake(self.floatingView.center.x + translation.x, self.floatingView.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.floatingView.superview];
}
@end


// ================= App 启动自动加载 UI =================
%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[RadarManager sharedManager] showFloatingUI];
    });
}
%end


// ================= 底层网络数据截取 (针对转转详情接口) =================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = request.URL.absoluteString;
    
    // 只拦截转转的商品详情接口
    if (![RadarManager sharedManager].isRadarActive || ![urlStr containsString:@"waresshow/moreInfo"]) {
        return %orig(request, completionHandler);
    }
    
    void (^customCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (data && !error) {
            // 将转转返回的数据转化为字符串，使用正则暴力解析，防 Crash
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (jsonString && jsonString.length > 0) {
                // 1. 判断是否命中 17.0 - 17.3.1
                BOOL isTarget = NO;
                if ([jsonString containsString:@"17.0"] || [jsonString containsString:@"17.1"] || 
                    [jsonString containsString:@"17.2"] || [jsonString containsString:@"17.3"]) {
                    if (![jsonString containsString:@"17.3.2"] && ![jsonString containsString:@"17.3.3"]) {
                        isTarget = YES;
                    }
                }
                
                if (isTarget) {
                    // 2. 正则提取商品标题
                    NSString *titleStr = @"未获取到机型";
                    NSRegularExpression *titleRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:title|subject|desc|name)\"\\s*:\\s*\"([^\"]+)\"" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *titleMatch = [titleRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (titleMatch) {
                        titleStr = [jsonString substringWithRange:[titleMatch rangeAtIndex:1]];
                    }
                    
                    // 3. 正则提取真实价格 (兼容转转的分/元混编逻辑)
                    NSString *priceStr = @"未知";
                    NSRegularExpression *priceRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:nowPrice|price|showPrice|salePrice)\"\\s*:\\s*\"?(\\d{4,})\"?" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *priceMatch = [priceRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (priceMatch) {
                        NSString *rawPrice = [jsonString substringWithRange:[priceMatch rangeAtIndex:1]];
                        double p = [rawPrice doubleValue];
                        double finalPrice = (p > 10000) ? (p / 100.0) : p;
                        priceStr = [NSString stringWithFormat:@"%.2f", finalPrice];
                    }
                    
                    // 4. 正则提取商品 ID
                    NSString *infoIdStr = @"未知";
                    NSRegularExpression *idRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:infoId|goodsId)\"\\s*:\\s*\"?(\\d{10,})\"?" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *idMatch = [idRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (idMatch) {
                        infoIdStr = [jsonString substringWithRange:[idMatch rangeAtIndex:1]];
                    }
                    
                    // 命中目标，主线程震动并更新 UI 面板
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        NSString *formattedString = [NSString stringWithFormat:@"%@\n¥%@ | 目标系统: 17.x\n商品编号: %@", titleStr, priceStr, infoIdStr];
                        [[RadarManager sharedManager] logMessage:formattedString];
                    });
                }
            }
        }
        
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    };
    
    return %orig(request, customCompletion);
}
%end
