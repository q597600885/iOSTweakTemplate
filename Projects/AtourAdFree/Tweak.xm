#import <UIKit/UIKit.h>

%hook AtourAdManager
- (bool)isAdEnabled {
    return NO;
}
%end
