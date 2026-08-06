#import <UIKit/UIKit.h>

// 1. 亚朵开屏专属视图拦截
%hook YDLaunchAnimationImageView

- (id)initWithFrame:(CGRect)frame {
    id origSelf = %orig;
    if (origSelf) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *view = (UIView *)origSelf;
            view.hidden = YES;
            [view removeFromSuperview];
        });
    }
    return origSelf;
}

%end

// 2. 拦截开屏控制器
%hook LaunchImageVC

- (void)viewDidLoad {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *vc = (UIViewController *)self;
        [vc.view removeFromSuperview];
        if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    });
}

%end

// 3. 全局窗口安全扫描 + 首次注入成功弹窗提示（只弹一次）
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
    // 全局视图去广告扫描
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = (UIWindow *)self;
        for (UIView *subview in window.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"Launch"] || [className containsString:@"Splash"] || [className containsString:@"Ad"]) {
                subview.hidden = YES;
                [subview removeFromSuperview];
            }
        }
    });

    // 首次注入弹窗提示（利用 static dispatch_once 确保整个生命周期只触发一次）
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL hasShown = [defaults boolForKey:@"AtourAdFree_Injected_Once"];
            
            if (!hasShown) {
                [defaults setBool:YES forKey:@"AtourAdFree_Injected_Once"];
                [defaults synchronize];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎉 亚朵去广告" 
                                                                                message:@"插件注入成功！开屏广告已永久去除，此提示仅出现一次。" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                
                UIWindow *window = (UIWindow *)self;
                UIViewController *rootVC = window.rootViewController;
                while (rootVC.presentedViewController) {
                    rootVC = rootVC.presentedViewController;
                }
                [rootVC presentViewController:alert animated:YES completion:nil];
            }
            
        });
    });
}

%end