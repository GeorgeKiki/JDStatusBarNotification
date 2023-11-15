//
//  NotificationStyle.swift
//  JDStatusBarNotification
//
//  Created by Markus on 11/12/23.
//  Copyright © 2023 Markus. All rights reserved.
//

import Foundation
import UIKit

/// These included styles let you easily change the visual appearance of a
/// notification without creating your own custom style.
///
/// Note that only the ``IncludedStatusBarNotificationStyle/defaultStyle`` is dynamic
/// and adjusts for light- & dark-mode. Other styles have a fixed appearance.
public enum IncludedStatusBarNotificationStyle {
    /// The default style. This is used when no other style was provided and the
    /// default style wasn't replaced by the user. This is a dynamic style matching
    /// the `light` style in light mode and `dark` style in dark mode.
    case defaultStyle
    /// A white background with a gray text.
    case light
    /// A nearly black background with a nearly white text.
    case dark
    /// A green background with a white text.
    case success
    /// A yellow background with a gray text.
    case warning
    /// A red background with a white text.
    case error
    /// A black background with a green bold monospace text.
    case matrix
}

/// Defines the appearance of the notification background.
public enum StatusBarNotificationBackgroundType {
    /// The background covers the full display width and the full status bar + navbar height.
    case fullWidth
    /// The background is a floating pill around the text. The pill size and appearance can be customized. This is the default.
    case pill
}

/// Defines the animation used during presentation and dismissal of the notification.
///
/// Default is ``StatusBarNotificationAnimationType/move``
public enum StatusBarNotificationAnimationType {
    /// Slide in from the top of the screen and slide back out to the top. This is the default.
    case move
    /// Fall down from the top and bounce a little bit, before coming to a rest. Slides back out to the top.
    case bounce
    /// Fade-in and fade-out in place. No movement animation.
    case fade
}

/// Defines the position of the progress bar, when used.
public enum StatusBarNotificationProgressBarPosition {
    /// The progress bar will be at the bottom of the notification content. This is the default.
    case bottom
    /// The progress bar will be at the center of the notification content.
    case center
    /// The progress bar will be at the top of the notification content.
    case top
}

/// Defines which `UIStatusBarStyle` should be used during presentation.
///
/// Note that if you use ``StatusBarNotificationBackgroundType/pill``, this is ignored.
/// The default is ``StatusBarNotificationSystemBarStyle/defaultStyle``.
public enum StatusBarNotificationSystemBarStyle {
    /// Matches the current viewController / window.
    case defaultStyle
    /// Forces light status bar contents (`UIStatusBarStyleLightContent`)
    case lightContent
    /// Forces dark status bar contents (`UIStatusBarStyleDarkContent`)
    case darkContent
}

/// Defines the appearance of a left-view, if set. This includes the activity indicator.
///
/// The default is ``StatusBarNotificationLeftViewAlignment/centerWithText``.
/// If no title or subtitle is set, the left-view is always fully centered.
///
/// Note: This can also influence the text layout as described below.
public enum StatusBarNotificationLeftViewAlignment {
    /// Aligns the left-view on the left side of the notification. The text is center-aligned unless it touches the left-view.
    ///
    /// If the text does touch the left-view, the text will also be left-aligned.
    /// If no title or subtitle is set, the left-view is always fully centered.
    case left
    /// Centers the left-view together with the text. The left-view will be positioned at the leading edge of the text. The text is left-aligned. This is the default.
    ///
    /// If no title or subtitle is set, the left-view is always fully centered.
    case centerWithText
}

/// A Style defines the appearance of a notification.
public class StatusBarNotificationStyle: NSObject {
    /// Defines the appearance of the title label.
    ///
    /// Defaults: `UIFontTextStyleFootnote`, color: `.gray` and adjusts for dark mode.
    /// The title's `textColor` is also used for the activity indicator, unless an explicit `leftViewStyle.tintColor` is set.
    /// The title's `textOffsetY` affects both the title, the subtitle and the left-view. And also the progressBar when using `.center` positioning.
    public var textStyle = StatusBarNotificationTextStyle()

    /// Defines the appearance of the subtitle label.
    ///
    /// Defaults: `UIFontTextStyleCaption1`, color: The title color at 66% opacity.
    ///
    /// The subtitle's .textOffsetY affects only the subtitle.
    public var subtitleStyle = StatusBarNotificationTextStyle(
        textColor: StatusBarNotificationTextStyle().textColor.withAlphaComponent(0.66),
        font: UIFont.preferredFont(forTextStyle: .caption1)
    )

    /// Defines the appearance of the notification background.
    ///
    /// That includes the ``StatusBarNotificationBackgroundStyle/backgroundColor``,
    /// the ``StatusBarNotificationBackgroundStyle/backgroundType``
    /// and the ``StatusBarNotificationBackgroundStyle/pillStyle`` (See ``StatusBarNotificationPillStyle``).
    public var backgroundStyle = StatusBarNotificationBackgroundStyle()

    /// Defines the appearance of the progress bar.
    public var progressBarStyle = StatusBarNotificationProgressBarStyle()

    /// Defines the appearance of a left-view, if set. It also applies to the activity indicator.
    public var leftViewStyle = StatusBarNotificationLeftViewStyle()

    /// Defines which `UIStatusBarStyle` should be used during presentation.
    ///
    /// If you use ``StatusBarNotificationBackgroundType/pill``, this is ignored.
    /// The default is ``StatusBarNotificationSystemBarStyle/defaultStyle``.
    public var systemStatusBarStyle: StatusBarNotificationSystemBarStyle = .defaultStyle

    /// Defines the animation used during presentation and dismissal of the notification.
    ///
    /// Default is ``StatusBarNotificationAnimationType/move``
    public var animationType: StatusBarNotificationAnimationType = .move

    /// Defines if the bar can be dismissed by the user swiping up. Default is `true`.
    ///
    /// Under the hood this enables/disables the internal `PanGestureRecognizer`.
    public var canSwipeToDismiss = true

    /// Defines if the bar can be touched to prevent a dismissal until the tap is released. Default is `true`.
    ///
    /// If ``StatusBarNotificationStyle/canTapToHold`` is `true`
    /// and ``StatusBarNotificationStyle/canDismissDuringUserInteraction`` is `false`,
    /// the user can tap the notification to prevent it from being dismissed until the tap is released.
    ///
    /// If you are utilizing a custom view and need custom touch handling (e.g. for a button), you should set this to `false`.
    /// Under the hood this enables/disables the internal `LongPressGestureRecognizer`.
    public var canTapToHold = true

    /// Defines if the bar is allowed to be dismissed while the user touches or pans the view.
    ///
    /// The default is `false`, meaning that a notification stays presented as long as a touch or pan is active.
    /// Once the touch is released, the view will be dismised (if a dismiss call was made during the interaction).
    /// Any passed-in dismiss completion block will still be executed, once the actual dismissal happened.
    public var canDismissDuringUserInteraction = false
}

/// Defines the appearance of a left-view, if set. It also applies to the activity indicator.
public class StatusBarNotificationLeftViewStyle: NSObject {
    /// The minimum distance between the left-view and the text. Defaults to 5.0.
    public var spacing: Double = 5.0

    /// An optional offset to adjust the left-views position. Default is `CGPointZero`.
    public var offset = CGPoint.zero

    /// Sets the tint color of the left-view. Default is `nil`.
    ///
    /// This applies to the activity indicator, or a custom left-view. The activity indicator
    /// defaults to the title text color, if no tintColor is specified.
    public var tintColor: UIColor? = nil

    /// The alignment of the left-view. The default is ``StatusBarNotificationLeftViewAlignment/centerWithText``
    /// If no title or subtitle is set, the left-view is always fully centered.
    public var alignment: StatusBarNotificationLeftViewAlignment = .centerWithText
}

/// Defines the appearance of a text label.
public class StatusBarNotificationTextStyle: NSObject {
    public init(textColor: UIColor? = nil, font: UIFont? = nil) {
        if let textColor {
            self.textColor = textColor
        }
        if let font {
            self.font = font
        }
    }

    /// The color of the  label.
    public var textColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(white: 0.95, alpha: 1.0)
        case .unspecified, .light:
            fallthrough
        @unknown default:
            return UIColor.gray
        }
    }

    /// The font of the label.
    public var font = UIFont.preferredFont(forTextStyle: .footnote)

    /// The text shadow color, the default is `nil`, meaning no shadow.
    public var shadowColor: UIColor? = nil

    /// The text shadow offset of the notification label. Default is `(1, 2)`
    public var shadowOffset = CGPoint(x: 1.0, y: 2.0)

    /// Offsets the text label on the y-axis. Default is `0.0`.
    public var textOffsetY: Double = 0.0
}

/// Defines the appearance of the pill, when using ``StatusBarNotificationBackgroundType/pill``
public class StatusBarNotificationPillStyle: NSObject {
    /// The height of the pill. Default is `50.0`.
    public var height: Double = 50.0

    /// The spacing between the pill and the statusbar or top of the screen.. Default is `0.0`.
    public var topSpacing: Double = 0.0

    /// The minimum with of the pill. Default is `200.0`.
    /// If this is lower than the pill height, the pill height is used as minimum width.
    public var minimumWidth: Double = 200.0

    /// The border color of the pill. The default is `nil`, meaning no border.
    public var borderColor: UIColor? = nil

    /// The width of the pill border. The default is `2.0`.
    public var borderWidth: Double = 2.0

    /// The shadow color of the pill shadow. The default is `nil`, meaning no shadow.
    public var shadowColor: UIColor? = nil

    /// The shadow radius of the pill shadow. The default is `4.0`.
    public var shadowRadius: Double = 4.0

    /// The shadow offset for the pill shadow. The default is `(0, 2)`.
    public var shadowOffset = CGPoint(x: 0, y: 2)
}

/// Defines the appearance of the notification background.
public class StatusBarNotificationBackgroundStyle: NSObject {
    /// The background color of the notification bar
    public var backgroundColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.050, green: 0.078, blue: 0.120, alpha: 1.000)
        case .unspecified, .light:
            fallthrough
        @unknown default:
            return UIColor.white
        }
    }

    /// The background type. Default is ``StatusBarNotificationBackgroundType/pill``
    public var backgroundType: StatusBarNotificationBackgroundType = .pill

    /// Defines the appearance of the pill, when using ``StatusBarNotificationBackgroundType/pill``
    public var pillStyle = StatusBarNotificationPillStyle()
}

/// Defines the appearance of the progress bar.
public class StatusBarNotificationProgressBarStyle: NSObject {
    /// The background color of the progress bar (on top of the notification bar)
    public var barColor: UIColor = .green

    /// The height of the progress bar. Default is `2.0`. The applied minimum is 0.5 and the maximum equals the full height of the notification.
    public var barHeight: Double = 2.0

    /// The position of the progress bar. Default is ``StatusBarNotificationProgressBarPosition/bottom``
    public var position: StatusBarNotificationProgressBarPosition = .bottom

    /// The insets of the progress bar. Default is `20.0`
    public var horizontalInsets: Double = 20.0

    /// Offsets the progress bar on the  y-axis. Default is `-5.0`.
    public var offsetY: Double = -5.0

    /// The corner radius of the progress bar. Default is `1.0`
    public var cornerRadius: Double = 1.0
}
