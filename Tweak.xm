#import <UIKit/UIKit.h>

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

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
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
