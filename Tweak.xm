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
    UIWindow *window = (UIWindow *)self;
    for (UIView *subview in window.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"Launch"] || [className containsString:@"Splash"] || [className containsString:@"Ad"]) {
            subview.hidden = YES;
            [subview removeFromSuperview];
        }
    }
}

%end
