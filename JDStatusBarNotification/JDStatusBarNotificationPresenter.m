//
//  JDStatusBarNotificationPresenter.m
//
//  Based on KGStatusBar by Kevin Gibbon
//
//  Created by Markus Emrich on 10/28/13.
//  Copyright 2013 Markus Emrich. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "JDStatusBarNotificationPresenter.h"

#import "JDStatusBarStyle.h"
#import "JDStatusBarIncludedStyles.h"
#import "JDStatusBarView.h"
#import "JDStatusBarView_Private.h"
#import "JDStatusBarWindow.h"
#import "JDStatusBarLayoutMarginHelper.h"
#import "JDStatusBarManagerHelper.h"
#import "UIApplication+MainWindow.h"
#import "JDStatusBarNotificationViewController.h"

@interface JDStatusBarNotificationPresenter () <
CAAnimationDelegate,
JDStatusBarNotificationViewControllerDelegate,
JDStatusBarViewDelegate
>
@end

@implementation JDStatusBarNotificationPresenter {
  UIWindowScene *_windowScene;
  JDStatusBarWindow *_overlayWindow;
  NSTimer *_dismissTimer;
  
  JDStatusBarStyle *_activeStyle;
  JDStatusBarStyle *_defaultStyle;
  NSMutableDictionary *_userStyles;
}

#pragma mark - Singleton

+ (instancetype)sharedPresenter {
  static dispatch_once_t once;
  static JDStatusBarNotificationPresenter *sharedInstance;
  dispatch_once(&once, ^ {
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

#pragma mark - Implementation

- (instancetype)init {
  self = [super init];
  if (self) {
    _defaultStyle = [JDStatusBarIncludedStyles defaultStyleWithName:JDStatusBarStyleDefault];
    _userStyles = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - Window Scene

- (void)setWindowScene:(UIWindowScene *)windowScene {
  _windowScene = windowScene;
}

#pragma mark - Custom Styles

- (void)updateDefaultStyle:(JDStatusBarPrepareStyleBlock)prepareBlock {
  NSAssert(prepareBlock != nil, @"No prepareBlock provided");
  _defaultStyle = prepareBlock([_defaultStyle copy]);
}

- (NSString*)addStyleNamed:(NSString*)identifier
                   prepare:(JDStatusBarPrepareStyleBlock)prepareBlock {
  NSAssert(identifier != nil, @"No identifier provided");
  NSAssert(prepareBlock != nil, @"No prepareBlock provided");
  
  JDStatusBarStyle *style = [_defaultStyle copy];
  [_userStyles setObject:prepareBlock(style) forKey:identifier];
  return identifier;
}

#pragma mark - Presentation

- (JDStatusBarView *)showWithStatus:(NSString *)status {
  return [self showWithStatus:status dismissAfterDelay:0.0 styleName:nil];
}

- (JDStatusBarView *)showWithStatus:(NSString *)status
                          styleName:(NSString * _Nullable)styleName {
  return [self showWithStatus:status dismissAfterDelay:0.0 styleName:styleName];
}

- (JDStatusBarView *)showWithStatus:(NSString *)status
                  dismissAfterDelay:(NSTimeInterval)timeInterval {
  return [self showWithStatus:status dismissAfterDelay:timeInterval styleName:nil];
}

- (JDStatusBarView *)showWithStatus:(NSString *)status
                  dismissAfterDelay:(NSTimeInterval)timeInterval
                          styleName:(NSString * _Nullable)styleName {
  JDStatusBarStyle *style = ([JDStatusBarIncludedStyles defaultStyleWithName:styleName]
                             ?: _userStyles[styleName]
                             ?: _defaultStyle);

  JDStatusBarView *view = [self showWithStatus:status style:style];
  if (timeInterval > 0.0) {
    [self dismissAfterDelay:timeInterval];
  }
  return view;
}

- (JDStatusBarView *)showWithStatus:(NSString *)status
                              style:(JDStatusBarStyle *)style {
  [self createWindowAndViewIfNeededWithStyle:style];

  JDStatusBarView *topBar = self.statusBarView;
  [topBar resetSubviewsIfNeeded];

  // prepare for new style
  if (style != _activeStyle) {
    _activeStyle = style;
    if (_activeStyle.animationType == JDStatusBarAnimationTypeFade) {
      topBar.alpha = 0.0;
      topBar.transform = CGAffineTransformIdentity;
    } else {
      topBar.alpha = 1.0;
      topBar.transform = CGAffineTransformMakeTranslation(0, -topBar.frame.size.height);
    }
  }
  
  // Force update the TopBar frame if the height is 0
  if (topBar.frame.size.height == 0) {
    [self updateContentFrame:JDStatusBarFrameForWindowScene(_windowScene)];
  }
  
  // cancel previous dismissing & remove animations
  [_dismissTimer invalidate];
  _dismissTimer = nil;
  [topBar.layer removeAllAnimations];
  
  // create & show window
  [_overlayWindow setHidden:NO];

  // update status & style
  [_overlayWindow.statusBarViewController setNeedsStatusBarAppearanceUpdate];
  [topBar setStatus:status];
  [topBar setStyle:style];
  
  // reset progress & activity
  [self showProgressBarWithPercentage:0.0];
  [topBar setDisplaysActivityIndicator:NO];
  
  // animate in
  BOOL animationsEnabled = (style.animationType != JDStatusBarAnimationTypeNone);
  if (animationsEnabled && style.animationType == JDStatusBarAnimationTypeBounce) {
    [self animateInWithBounceAnimation];
  } else {
    [UIView animateWithDuration:(animationsEnabled ? 0.4 : 0.0) animations:^{
      topBar.alpha = 1.0;
      topBar.transform = CGAffineTransformIdentity;
    }];
  }
  
  return topBar;
}

#pragma mark - JDStatusBarViewDelegate

- (void)statusBarViewDidPanToDismiss {
  [self dismissAnimated:YES duration:0.25 completion:nil];
}

#pragma mark - Dismissal

static NSString *const kJDStatusBarDismissCompletionBlockKey = @"JDSBDCompletionBlockKey";

- (void)dismissAfterDelay:(NSTimeInterval)delay {
  [self dismissAfterDelay:delay completion:nil];
}

- (void)dismissAfterDelay:(NSTimeInterval)delay
             completion:(void(^ _Nullable)(void))completion {
  [_dismissTimer invalidate];

  NSDictionary *userInfo = nil;
  if (completion != nil) {
    userInfo = @{kJDStatusBarDismissCompletionBlockKey: completion};
  }

  _dismissTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                   target:self
                                                 selector:@selector(dismissTimerFired:)
                                                 userInfo:userInfo
                                                  repeats:NO];
}

- (void)dismissTimerFired:(NSTimer *)timer {
  [self dismissAnimated:YES
             completion:timer.userInfo[kJDStatusBarDismissCompletionBlockKey]];
}

- (void)dismissAnimated:(BOOL)animated {
  [self dismissAnimated:animated completion:nil];
}

- (void)dismissAnimated:(BOOL)animated
             completion:(void(^ _Nullable)(void))completion {
  [self dismissAnimated:animated duration:0.4 completion:completion];
}

- (void)dismissAnimated:(BOOL)animated
               duration:(CGFloat)duration
             completion:(void(^ _Nullable)(void))completion {
  [_dismissTimer invalidate];
  _dismissTimer = nil;

  // disable pan gesture
  JDStatusBarView *topBar = self.statusBarView;
  topBar.panGestureRecognizer.enabled = NO;
  
  // check animation type
  BOOL animationsEnabled = (_activeStyle.animationType != JDStatusBarAnimationTypeNone);
  animated &= animationsEnabled;
  
  dispatch_block_t animation = ^{
    if (self->_activeStyle.animationType == JDStatusBarAnimationTypeFade) {
      topBar.alpha = 0.0;
    } else {
      topBar.transform = CGAffineTransformMakeTranslation(0, - topBar.frame.size.height);
    }
  };
  
  __weak __typeof(self) weakSelf = self;
  void(^animationCompletion)(BOOL) = ^(BOOL finished) {
    [weakSelf resetWindowAndViews];
    if (completion != nil) {
      completion();
    }
  };
  
  if (animated) {
    // animate out
    [UIView animateWithDuration:duration animations:animation completion:animationCompletion];
  } else {
    animation();
    animationCompletion(YES);
  }
}

- (void)resetWindowAndViews {
  [_overlayWindow removeFromSuperview];
  [_overlayWindow setHidden:YES];
  _overlayWindow.rootViewController = nil;
  _overlayWindow = nil;
  _activeStyle = nil;
}

#pragma mark - Bounce Animation

- (void)animateInWithBounceAnimation {
  //don't animate in, if topBar is already fully visible
  JDStatusBarView *topBar = self.statusBarView;
  if (topBar.frame.origin.y >= 0) {
    return;
  }
  
  // easing function (based on github.com/robb/RBBAnimation)
  CGFloat(^RBBEasingFunctionEaseOutBounce)(CGFloat) = ^CGFloat(CGFloat t) {
    if (t < 4.0 / 11.0) return pow(11.0 / 4.0, 2) * pow(t, 2);
    if (t < 8.0 / 11.0) return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(t - 6.0 / 11.0, 2);
    if (t < 10.0 / 11.0) return 15.0 /16.0 + pow(11.0 / 4.0, 2) * pow(t - 9.0 / 11.0, 2);
    return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(t - 21.0 / 22.0, 2);
  };
  
  // create values
  int fromCenterY=-20, toCenterY=0, animationSteps=100;
  NSMutableArray *values = [NSMutableArray arrayWithCapacity:animationSteps];
  for (int t = 1; t<=animationSteps; t++) {
    float easedTime = RBBEasingFunctionEaseOutBounce((t*1.0)/animationSteps);
    float easedValue = fromCenterY + easedTime * (toCenterY-fromCenterY);
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, easedValue, 0)]];
  }
  
  // build animation
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  animation.duration = 0.66;
  animation.values = values;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  animation.delegate = self;
  [topBar.layer setValue:@(toCenterY) forKeyPath:animation.keyPath];
  [topBar.layer addAnimation:animation forKey:@"JDBounceAnimation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  JDStatusBarView *topBar = self.statusBarView;
  topBar.transform = CGAffineTransformIdentity;
  [topBar.layer removeAllAnimations];
}

#pragma mark - Modifications

- (void)updateStatus:(NSString *)status {
  [self.statusBarView setStatus:status];
}

- (void)showProgressBarWithPercentage:(CGFloat)percentage {
  [self.statusBarView setProgressBarPercentage:percentage];
}

- (void)showProgressBarWithPercentage:(CGFloat)percentage
                    animationDuration:(CGFloat)animationDuration
                           completion:(void(^ _Nullable)(JDStatusBarNotificationPresenter *presenter))completion {
  __weak __typeof(self) weakSelf = self;
  [self.statusBarView setProgressBarPercentage:percentage
                             animationDuration:animationDuration
                                    completion:^{
    if (completion) {
      completion(weakSelf);
    }
  }];
}

- (void)showActivityIndicator:(BOOL)show {
  [self.statusBarView setDisplaysActivityIndicator:show];
}

static CGFloat navBarHeight(UIWindowScene *windowScene) {
  if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) &&
      UIInterfaceOrientationIsLandscape(JDStatusBarOrientationForWindowScene(windowScene))) {
    return 32.0;
  }
  return 44.0;
}

#pragma mark - State

- (BOOL)isVisible {
  return (_overlayWindow != nil);
}

- (JDStatusBarView *)statusBarView {
  return _overlayWindow.statusBarViewController.statusBarView;
}

#pragma mark - View/Window factories

- (void)createWindowAndViewIfNeededWithStyle:(JDStatusBarStyle *)style {
  if(_overlayWindow == nil) {
    JDStatusBarWindow *window = [[JDStatusBarWindow alloc] initWithStyle:style windowScene:_windowScene];
    window.statusBarViewController.delegate = self;
    _overlayWindow = window;

    JDStatusBarView *topBar = window.statusBarViewController.statusBarView;
    topBar.delegate = self;
    if (style.animationType != JDStatusBarAnimationTypeFade) {
      topBar.transform = CGAffineTransformMakeTranslation(0, - topBar.frame.size.height);
    } else {
      topBar.alpha = 0.0;
    }
    
    [self updateContentFrame:JDStatusBarFrameForWindowScene(_windowScene)];
  }
}

#pragma mark - Rotation

- (void)animationsForViewTransitionToSize:(CGSize)size {
  // update window & statusbar
  [self updateContentFrame:CGRectMake(0, 0, size.width, JDStatusBarFrameForWindowScene(_windowScene).size.height)];
  // relayout progress bar
  [self showProgressBarWithPercentage:self.statusBarView.progressBarPercentage];
}

#pragma mark - Sizing

- (void)updateContentFrame:(CGRect)rect {
  // match main window transform & frame
  UIWindow *window = [[UIApplication sharedApplication] mainApplicationWindowIgnoringWindow:_overlayWindow];
  _overlayWindow.transform = window.transform;
  _overlayWindow.frame = window.frame;
  
  // default to window width
  if (CGRectIsEmpty(rect)) {
    rect = CGRectMake(0, 0, window.frame.size.width, 0.0);
  }
  
  // update top bar frame
  CGFloat heightIncludingNavBar = rect.size.height + navBarHeight(window.windowScene);
  self.statusBarView.frame = CGRectMake(0, 0, rect.size.width, heightIncludingNavBar);
}

@end
