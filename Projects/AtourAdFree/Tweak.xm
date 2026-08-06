#import <UIKit/UIKit.h>

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
    // 用静态变量确保整个 App 生命周期只弹一次，方便测试
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎉 注入成功测试" 
                                                                            message:@"AtourAdFree 插件已经成功加载并运行！" 
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            
            // 获取当前活跃的根控制器并弹窗
            UIWindow *window = (UIWindow *)self;
            UIViewController *rootVC = window.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
            
        });
    });
}

%end
