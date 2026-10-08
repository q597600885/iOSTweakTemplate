#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// ================= 超级本地文件日志系统 =================
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


// ================= 全局 UI 管理器 =================
@interface RadarManager : NSObject <UITextFieldDelegate>
@property (nonatomic, strong) UIView *floatingView;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, assign) BOOL isRadarActive;
@property (nonatomic, assign) NSInteger hitCount;

// 新增：三个真实的输入框
@property (nonatomic, strong) UITextField *modelField;
@property (nonatomic, strong) UITextField *versionField;
@property (nonatomic, strong) UITextField *capacityField;

// 存储用户当前的输入值
@property (nonatomic, copy) NSString *targetModel;
@property (nonatomic, copy) NSString *targetVersion;
@property (nonatomic, copy) NSString *targetCapacity;

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
        return;
    }
    
    UIWindow *keyWindow = nil;
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
    
    if (!keyWindow) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }
    if (!keyWindow) return;
    
    // 1. 主面板
    self.floatingView = [[UIView alloc] initWithFrame:CGRectMake(10, 100, 320, 480)];
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
    
    // 3. 动态条件输入框 (替换了原来的静态标签)
    self.modelField = [self createTextFieldWithFrame:CGRectMake(15, 45, 90, 30) placeholder:@"机型(如15 Pro)" text:@"15 Pro Max"];
    [self.floatingView addSubview:self.modelField];
    
    self.versionField = [self createTextFieldWithFrame:CGRectMake(115, 45, 90, 30) placeholder:@"系统(如17.1)" text:@"17."];
    [self.floatingView addSubview:self.versionField];
    
    self.capacityField = [self createTextFieldWithFrame:CGRectMake(215, 45, 90, 30) placeholder:@"容量(如256)" text:@"256G"];
    [self.floatingView addSubview:self.capacityField];
    
    // 初始化拦截条件
    [self updateTargetValues];
    
    // 4. 控制按钮
    UIButton *toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    toggleBtn.frame = CGRectMake(15, 85, 90, 30);
    toggleBtn.backgroundColor = [UIColor systemBlueColor];
    toggleBtn.layer.cornerRadius = 6;
    toggleBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [toggleBtn setTitle:@"开始提取" forState:UIControlStateNormal];
    [toggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [toggleBtn addTarget:self action:@selector(toggleRadar:) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:toggleBtn];
    
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(115, 85, 90, 30);
    clearBtn.backgroundColor = [UIColor systemGrayColor];
    clearBtn.layer.cornerRadius = 6;
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [clearBtn setTitle:@"清除列表" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [clearBtn addTarget:self action:@selector(clearLogs) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:clearBtn];
    
    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    copyBtn.frame = CGRectMake(215, 85, 90, 30);
    copyBtn.backgroundColor = [UIColor systemOrangeColor];
    copyBtn.layer.cornerRadius = 6;
    copyBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [copyBtn setTitle:@"复制全部内容" forState:UIControlStateNormal];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [copyBtn addTarget:self action:@selector(copyLogs) forControlEvents:UIControlEventTouchUpInside];
    [self.floatingView addSubview:copyBtn];
    
    // 5. 日志文本框
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, 125, 290, 340)];
    self.logTextView.editable = NO;
    self.logTextView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.logTextView.layer.cornerRadius = 6;
    self.logTextView.font = [UIFont systemFontOfSize:12];
    self.logTextView.textColor = [UIColor darkGrayColor];
    [self.floatingView addSubview:self.logTextView];
    
    // 6. 收起键盘的点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO; // 不阻断拖拽等其他交互
    [self.floatingView addGestureRecognizer:tap];
    
    // 7. 拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.cancelsTouchesInView = NO; // 极其重要：防止拖拽手势导致无法点击输入框
    [self.floatingView addGestureRecognizer:pan];
    
    [keyWindow addSubview:self.floatingView];
    RadarLog(@"带有动态输入框的 UI 挂载完成");
}

// 快速创建输入框的辅助方法
- (UITextField *)createTextFieldWithFrame:(CGRect)frame placeholder:(NSString *)placeholder text:(NSString *)text {
    UITextField *tf = [[UITextField alloc] initWithFrame:frame];
    tf.placeholder = placeholder;
    tf.text = text;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.font = [UIFont systemFontOfSize:11];
    tf.returnKeyType = UIReturnKeyDone;
    tf.delegate = self;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    // 监听文字变化
    [tf addTarget:self action:@selector(updateTargetValues) forControlEvents:UIControlEventEditingChanged];
    return tf;
}

// 每次你在框里打字，这个方法都会实时同步条件给底层拦截器
- (void)updateTargetValues {
    self.targetModel = self.modelField.text ?: @"";
    self.targetVersion = self.versionField.text ?: @"";
    self.targetCapacity = self.capacityField.text ?: @"";
    RadarLog(@"拦截条件已更新: 机型[%@], 系统[%@], 容量[%@]", self.targetModel, self.targetVersion, self.targetCapacity);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)dismissKeyboard {
    [self.floatingView endEditing:YES];
}

- (void)toggleRadar:(UIButton *)sender {
    self.isRadarActive = !self.isRadarActive;
    if (self.isRadarActive) {
        [sender setTitle:@"暂停提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemRedColor];
        RadarLog(@"雷达已开启");
    } else {
        [sender setTitle:@"开始提取" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemBlueColor];
        RadarLog(@"雷达已暂停");
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


// ================= 插件初始化 =================
%ctor {
    RadarLog(@"[插件加载] Tweak dylib 成功注入");
}

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[RadarManager sharedManager] showFloatingUI];
        });
    });
}
%end


// ================= 底层网络数据截取 & 动态条件判断 =================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *urlStr = request.URL.absoluteString;
    
    if (![RadarManager sharedManager].isRadarActive || ![urlStr containsString:@"waresshow/moreInfo"]) {
        return %orig(request, completionHandler);
    }
    
    // 从单例中获取你输入的条件 (转小写，方便忽略大小写匹配)
    NSString *tModel = [RadarManager sharedManager].targetModel.lowercaseString;
    NSString *tVersion = [RadarManager sharedManager].targetVersion.lowercaseString;
    NSString *tCapacity = [RadarManager sharedManager].targetCapacity.lowercaseString;
    
    void (^customCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (data && !error) {
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (jsonString && jsonString.length > 0) {
                NSString *jsonLower = jsonString.lowercaseString;
                BOOL isTarget = YES;
                
                // 1. 匹配机型 (留空则不限制)
                if (tModel.length > 0) {
                    NSArray *arr = [tModel componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，| /"]];
                    BOOL match = NO;
                    for (NSString *k in arr) {
                        if (k.length > 0 && [jsonLower containsString:k]) { match = YES; break; }
                    }
                    if (!match) isTarget = NO;
                }
                
                // 2. 匹配系统版本 (留空则不限制)
                if (isTarget && tVersion.length > 0) {
                    NSArray *arr = [tVersion componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，| /"]];
                    BOOL match = NO;
                    for (NSString *k in arr) {
                        if (k.length > 0 && [jsonLower containsString:k]) { match = YES; break; }
                    }
                    if (!match) isTarget = NO;
                }
                
                // 3. 匹配容量 (留空则不限制)
                if (isTarget && tCapacity.length > 0) {
                    NSArray *arr = [tCapacity componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",，| /"]];
                    BOOL match = NO;
                    for (NSString *k in arr) {
                        if (k.length > 0 && [jsonLower containsString:k]) { match = YES; break; }
                    }
                    if (!match) isTarget = NO;
                }
                
                // 命中目标：执行正则提取并在屏幕上输出
                if (isTarget) {
                    // 正则提取商品标题
                    NSString *titleStr = @"未获取到机型";
                    NSRegularExpression *titleRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:title|subject|desc|name)\"\\s*:\\s*\"([^\"]+)\"" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *titleMatch = [titleRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (titleMatch) titleStr = [jsonString substringWithRange:[titleMatch rangeAtIndex:1]];
                    
                    // 正则提取真实价格
                    NSString *priceStr = @"未知";
                    NSRegularExpression *priceRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:nowPrice|price|showPrice|salePrice)\"\\s*:\\s*\"?(\\d{4,})\"?" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *priceMatch = [priceRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (priceMatch) {
                        NSString *rawPrice = [jsonString substringWithRange:[priceMatch rangeAtIndex:1]];
                        double p = [rawPrice doubleValue];
                        double finalPrice = (p > 10000) ? (p / 100.0) : p;
                        priceStr = [NSString stringWithFormat:@"%.2f", finalPrice];
                    }
                    
                    // 正则提取商品 ID
                    NSString *infoIdStr = @"未知";
                    NSRegularExpression *idRegex = [NSRegularExpression regularExpressionWithPattern:@"\"(?:infoId|goodsId)\"\\s*:\\s*\"?(\\d{10,})\"?" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSTextCheckingResult *idMatch = [idRegex firstMatchInString:jsonString options:0 range:NSMakeRange(0, jsonString.length)];
                    if (idMatch) infoIdStr = [jsonString substringWithRange:[idMatch rangeAtIndex:1]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        NSString *formattedString = [NSString stringWithFormat:@"%@\n¥%@ | 编号: %@", titleStr, priceStr, infoIdStr];
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
