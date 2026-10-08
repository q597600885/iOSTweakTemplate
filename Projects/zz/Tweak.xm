#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ================= 超级本地文件日志系统 =================
// 作用：把日志写到 App 的 Documents 目录下，非越狱也能用“文件”App查看
void RadarLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logFilePath = [docPath stringByAppendingPathComponent:@"RadarDebugLog.txt"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", dateString, message];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logLine writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}


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
    if (self.floatingView) {
        RadarLog(@"悬浮窗已经存在，跳过创建");
        return;
    }
    
    RadarLog(@"开始尝试寻找 KeyWindow 来挂载悬浮窗...");
    UIWindow *keyWindow = nil;
    
    // 适配各种版本的窗口获取
    for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
        }
    }
    
    // 兜底获取方式
    if (!keyWindow) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }
    
    if (!keyWindow) {
        RadarLog(@"[严重错误] 找不到 KeyWindow，悬浮窗挂载失败！");
        return;
    }
    
    RadarLog(@"成功找到 KeyWindow: %@，开始绘制界面", keyWindow);
    
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
    
    // 3. 控制按钮
    UIButton *toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    toggleBtn.frame = CGRectMake(15, 55, 90, 30);
    toggleBtn.backgroundColor = [UIColor systemBlueColor];
    toggleBtn.layer.cornerRadius = 6;
    [toggleBtn setTitle:@"开始提取" forState:UIControlStateNormal];
    [toggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toggleBtn addTarget:self action:@selector(toggleRadar:) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:toggleBtn];
    
    // 4. 日志文本框
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 95, 290, 340)];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.logTextView.layer.cornerRadius = 6;
    self.logTextView.font = [UIFont systemFontOfSize:12];
    self.logTextView.textColor = [UIColor darkGrayColor];
    [self.floatingView addSubview:self.logTextView];
    
    // 5. 拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.floatingView addGestureRecognizer:pan];
    
    [keyWindow addSubview:self.floatingView];
    RadarLog(@"UI 挂载完成，悬浮窗展示成功！");
}

- (void)toggleRadar:(UIButton *)sender {
    self.isRadarActive = !self.isRadarActive;
    if (self.isRadarActive) {
        [sender setTitle:@"暂停提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemRedColor];
        RadarLog(@"雷达已开启，正在监听底层网络...");
    } else {
        [sender setTitle:@"开始提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemBlueColor];
        RadarLog(@"雷达已暂停。");
    }
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


// ================= 插件初始化入口 =================
%ctor {
    RadarLog(@"[插件加载] Tweak dylib 成功注入，准备启动...");
}


// ================= 更换更底层的 UI 触发点 =================
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    RadarLog(@"拦截到 [UIWindow makeKeyAndVisible]：%@", self);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RadarLog(@"正在延迟 3 秒触发悬浮窗绘制...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[RadarManager sharedManager] showFloatingUI];
        });
    });
}
%end


// ================= 底层网络数据截取 =================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = request.URL.absoluteString;
    
    // 只拦截转转详情，减轻性能压力
    if (![urlStr containsString:@"waresshow/moreInfo"]) {
        return %orig(request, completionHandler);
    }
    
    RadarLog(@"[网络拦截] 捕捉到详情请求: %@", urlStr);
    
    if (![RadarManager sharedManager].isRadarActive) {
        return %orig(request, completionHandler);
    }
    
    void (^customCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (data && !error) {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            RadarLog(@"[网络返回] 成功解析返回数据，长度: %lu", (unsigned long)jsonString.length);
            
            if (jsonString && jsonString.length > 0) {
                BOOL isTarget = NO;
                if ([jsonString containsString:@"17.0"] || [jsonString containsString:@"17.1"] || 
                    [jsonString containsString:@"17.2"] || [jsonString containsString:@"17.3"]) {
                    if (![jsonString containsString:@"17.3.2"] && ![jsonString containsString:@"17.3.3"]) {
                        isTarget = YES;
                    }
                }
                
                if (isTarget) {
                    RadarLog(@"[命中天命机] 目标系统匹配成功！");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        NSString *formattedString = @"检测到目标机器，请查看详细信息！";
                        [[RadarManager sharedManager] logMessage:formattedString];
                    });
                }
            }
        } else {
            RadarLog(@"[网络错误] 请求失败或数据为空: %@", error);
        }
        
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    };
    
    return %orig(request, customCompletion);
}
%end
