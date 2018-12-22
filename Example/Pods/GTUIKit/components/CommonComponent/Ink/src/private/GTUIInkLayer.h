//
//  GTUIInkLayer.h
//  GTCatalog
//
//  Created by liuxc on 2018/11/7.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@protocol GTUIInkLayerDelegate;

@interface GTUIInkLayer : CAShapeLayer


/**
 Ink layer animation delegate. Clients set this delegate to receive updates when ink layer
 animations start and end.
 */
@property(nonatomic, weak, nullable) id<GTUIInkLayerDelegate> animationDelegate;

/**
 The start ink ripple spread animation has started and is active.
 */
@property(nonatomic, assign, readonly, getter=isStartAnimationActive) BOOL startAnimationActive;

/**
 Delay time in milliseconds before the end ink ripple spread animation begins.
 */
@property(nonatomic, assign) CGFloat endAnimationDelay;

/**
 The radius the ink ripple grows to when ink ripple ends.

 Default value is half the diagonal of the containing frame plus 10pt.
 */
@property(nonatomic, assign) CGFloat finalRadius;

/**
 The radius the ink ripple starts to grow from when the ink ripple begins.

 Default value is half the diagonal of the containing frame multiplied by 0.6.
 */
@property(nonatomic, assign) CGFloat initialRadius;

/**
 Maximum radius of the ink. If this is not set then the final radius value is used.
 */
@property(nonatomic, assign) CGFloat maxRippleRadius;

/**
 The color of the ink ripple.
 */
@property(nonatomic, strong, nonnull) UIColor *inkColor;

/**
 Starts the ink ripple animation at a specified point.
 */
- (void)startAnimationAtPoint:(CGPoint)point;


/**
 Starts the ink ripple

 @param point the point where to start the ink ripple
 @param animated if to animate the ripple or not
 */
- (void)startInkAtPoint:(CGPoint)point animated:(BOOL)animated;

/**
 Changes the opacity of the ink ripple depending on if touch point is contained within or
 outside of the ink layer.
 */
- (void)changeAnimationAtPoint:(CGPoint)point;

/**
 Ends the ink ripple animation.
 */
- (void)endAnimationAtPoint:(CGPoint)point;


/**
 Ends the ink ripple

 @param point the point where to end the ink ripple
 @param animated if to animate the ripple or not
 */
- (void)endInkAtPoint:(CGPoint)point animated:(BOOL)animated;


@end

@protocol GTUIInkLayerDelegate <CALayerDelegate>

@optional

/**
 Called when the ink ripple animation begins.

 @param inkLayer The GTUIInkLayer that starts animating.
 */
- (void)inkLayerAnimationDidStart:(nonnull GTUIInkLayer *)inkLayer;

/**
 Called when the ink ripple animation ends.

 @param inkLayer The GTUIInkLayer that ends animating.
 */
- (void)inkLayerAnimationDidEnd:(nonnull GTUIInkLayer *)inkLayer;

@end
