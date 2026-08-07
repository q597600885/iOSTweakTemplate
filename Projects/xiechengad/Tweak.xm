#import <UIKit/UIKit.h>

// 递归获取当前最顶层的 UIViewController
static UIViewController *getTopViewController() {
    UIWindow *keyWindow = nil;
    
    // 兼容 iOS 13+ 的 SceneDelegate
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    }
    
    // 兜底方案（iOS 12 及以下，或非 Scene App）
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    UIViewController *topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

// 显示注入成功弹窗
static void showInjectAlert() {
    // 稍作延迟，确保主界面完全渲染完成
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *topVC = getTopViewController();
        if (!topVC) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"注入成功 🎉"
                                                                       message:@"Tweak 插件已成功加载到当前应用！"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];

        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

%ctor {
    // 监听应用启动完成通知
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        
        // ----------------------------------------------------
        // 情况 A：仅首次启动弹窗一次（使用 NSUserDefaults 标记）
        // ----------------------------------------------------
        /*
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:@"HasShownFirstInjectAlert"]) {
            showInjectAlert();
            [defaults setBool:YES forKey:@"HasShownFirstInjectAlert"];
            [defaults synchronize];
        }
        */

        // ----------------------------------------------------
        // 情况 B：每次打开 App 都弹窗（调试阶段推荐）
        // ----------------------------------------------------
        showInjectAlert();
    }];
}
