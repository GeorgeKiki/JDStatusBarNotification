//
//

#import "JDStatusBarNotificationViewController.h"

#import "UIApplication+MainWindow.h"

// A custom view controller, so the statusBarStyle & rotation behaviour is correct
@implementation JDStatusBarNotificationViewController

// mainVC determination

- (UIViewController *)jdsb_mainController {
  UIWindow *mainAppWindow = [[UIApplication sharedApplication] mainApplicationWindowIgnoringWindow:self.view.window];
  UIViewController *topController = mainAppWindow.rootViewController;
  
  while(topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  
  if ([topController respondsToSelector:@selector(topViewController)]) {
    topController = [((UINavigationController *)topController) topViewController];
  }

  // ensure we never end up with recursive calls
  if (topController == self) {
    return nil;
  }
  
  return topController;
}

// rotation

- (BOOL)shouldAutorotate {
  return [[self jdsb_mainController] shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [[self jdsb_mainController] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return [[self jdsb_mainController] preferredInterfaceOrientationForPresentation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self.delegate animationsForViewTransitionToSize:size];
  } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    //
  }];
}

// statusbar

static BOOL JDUIViewControllerBasedStatusBarAppearanceEnabled() {
  static BOOL enabled = YES;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    NSNumber *value = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (value != nil) {
      enabled = [value boolValue];
    }
  });
  
  return enabled;
}

- (void)setStatusBarSystemStyle:(JDStatusBarSystemStyle)statusBarSystemStyle {
  if (_statusBarSystemStyle != statusBarSystemStyle) {
    _statusBarSystemStyle = statusBarSystemStyle;
    [self setNeedsStatusBarAppearanceUpdate];
  }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  switch (_statusBarSystemStyle) {
    case JDStatusBarSystemStyleDefault:
      return [self defaultStatusBarStyle];
    case JDStatusBarSystemStyleLightContent:
      return UIStatusBarStyleLightContent;
    case JDStatusBarSystemStyleDarkContent:
      return UIStatusBarStyleDarkContent;
  }
}

- (UIStatusBarStyle)defaultStatusBarStyle {
  if(JDUIViewControllerBasedStatusBarAppearanceEnabled()) {
    return [[self jdsb_mainController] preferredStatusBarStyle];
  }
  
  return [super preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden {
  if(JDUIViewControllerBasedStatusBarAppearanceEnabled()) {
    return [[self jdsb_mainController] prefersStatusBarHidden];
  }
  return [super prefersStatusBarHidden];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
  return UIStatusBarAnimationFade;
}

@end