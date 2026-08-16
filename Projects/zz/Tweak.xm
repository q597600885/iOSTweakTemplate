#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

// 记录已经触发过提醒的文本，防止同一个控件重绘导致无限弹窗
static NSMutableSet *alertedSet;

%ctor {
    alertedSet = [[NSMutableSet alloc] init];
}

%hook UILabel

- (void)setText:(NSString *)text {
    %orig;
    
    // 过滤掉空文本和过长的无关长文，优化性能
    if (!text || text.length == 0 || text.length > 50) {
        return;
    }
    
    // 粗略锁定是否包含版本号关键字
    if ([text containsString:@"17.0"] || 
        [text containsString:@"17.1"] || 
        [text containsString:@"17.2"] || 
        [text containsString:@"17.3"]) {
        
        // 排除掉 17.3.2 甚至 17.3.3 等非目标版本
        if ([text containsString:@"17.3.2"] || [text containsString:@"17.3.3"]) {
            return;
        }
        
        // 如果包含 "系统" 或 "iOS" 字眼，命中率更高
        if ([text.lowercaseString containsString:@"ios"] || [text containsString:@"系统"] || [text containsString:@"版本"]) {
            
            if ([alertedSet containsObject:text]) {
                return;
            }
            [alertedSet addObject:text];
            
            // 触发系统震动，盲扫时非常管用
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            // 切换到主线程弹窗
            dispatch_async(dispatch_get_main_queue(), ^{
                UIWindow *keyWindow = nil;
                
                // 修复: 适配 iOS 15+ 的 UIWindowScene 窗口获取方式
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *windowScene = (UIWindowScene *)scene;
                        for (UIWindow *window in windowScene.windows) {
                            if (window.isKeyWindow) {
                                keyWindow = window;
                                break;
                            }
                        }
                    }
                }
                
                // 兜底方案，为了绝对安全包裹忽略警告的宏
                if (!keyWindow) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
                }
                
                if (!keyWindow) return;

                UIViewController *topVC = keyWindow.rootViewController;
                while (topVC.presentedViewController) {
                    topVC = topVC.presentedViewController;
                }
                
                if (!topVC) return;
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎯 天命机降临" 
                                                                               message:[NSString stringWithFormat:@"发现目标:\n%@", text] 
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"冲！" style:UIAlertActionStyleDefault handler:nil]];
                
                [topVC presentViewController:alert animated:YES completion:nil];
            });
        }
    }
}

%end
