#import <UIKit/UIKit.h>

%hook LaunchImageVC

- (void)viewDidLoad {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL hasShownAlert = [defaults boolForKey:@"AtourAdFree_HasShownSuccessAlert"];
        
        if (!hasShownAlert) {
            [defaults setBool:YES forKey:@"AtourAdFree_HasShownSuccessAlert"];
            [defaults synchronize];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AtourAdFree" 
                                                                            message:@"Plugin injected successfully!" 
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            UIWindow *mainWindow = nil;
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            mainWindow = window;
                            break;
                        }
                    }
                }
            }
            
            UIViewController *rootVC = mainWindow.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

%end
