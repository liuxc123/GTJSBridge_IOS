//
//  GTUIButton.m
//  GTCatalog
//
//  Created by liuxc on 2018/11/7.
//

#import "GTUIButton.h"

#import "GTInk.h"
#import "GTMath.h"
#import "GTShadowLayer.h"
#import "GTTypography.h"
#import "private/GTUIButton+Subclassing.h"

static const CGFloat GTUIButtonMinimumTouchTargetHeight = 40;
static const CGFloat GTUIButtonMinimumTouchTargetWidth = 40;
static const CGFloat GTUIButtonDefaultCornerRadius = 2.0;

static const NSTimeInterval GTUIButtonAnimationDuration = 0.2;

// https://material.io/go/design-buttons#buttons-main-buttons
static const CGFloat GTUIButtonDisabledAlpha = 0.12f;

// Blue 500 from https://material.io/go/design-color-theming#color-color-palette .
static const uint32_t GTUIButtonDefaultBackgroundColor = 0x191919;

// Creates a UIColor from a 24-bit RGB color encoded as an integer.
static inline UIColor *GTUIColorFromRGB(uint32_t rgbValue) {
    return [UIColor colorWithRed:((CGFloat)((rgbValue & 0xFF0000) >> 16)) / 255
                           green:((CGFloat)((rgbValue & 0x00FF00) >> 8)) / 255
                            blue:((CGFloat)((rgbValue & 0x0000FF) >> 0)) / 255
                           alpha:1];
}

static NSAttributedString *uppercaseAttributedString(NSAttributedString *string) {
    // Store the attributes.
    NSMutableArray<NSDictionary *> *attributes = [NSMutableArray array];
    [string enumerateAttributesInRange:NSMakeRange(0, [string length])
                               options:0
                            usingBlock:^(NSDictionary *attrs, NSRange range, __unused BOOL *stop) {
                                [attributes addObject:@{
                                                        @"attrs" : attrs,
                                                        @"range" : [NSValue valueWithRange:range]
                                                        }];
                            }];

    // Make the string uppercase.
    NSString *uppercaseString = [[string string] uppercaseStringWithLocale:[NSLocale currentLocale]];

    // Apply the text and attributes to a mutable copy of the title attributed string.
    NSMutableAttributedString *mutableString = [string mutableCopy];
    [mutableString replaceCharactersInRange:NSMakeRange(0, [string length])
                                 withString:uppercaseString];
    for (NSDictionary *attribute in attributes) {
        [mutableString setAttributes:attribute[@"attrs"] range:[attribute[@"range"] rangeValue]];
    }

    return [mutableString copy];
}

@interface GTUIButton () {
    // For each UIControlState.
    NSMutableDictionary<NSNumber *, NSNumber *> *_userElevations;
    NSMutableDictionary<NSNumber *, UIColor *> *_backgroundColors;
    NSMutableDictionary<NSNumber *, UIColor *> *_borderColors;
    NSMutableDictionary<NSNumber *, NSNumber *> *_borderWidths;
    NSMutableDictionary<NSNumber *, UIColor *> *_shadowColors;
    NSMutableDictionary<NSNumber *, UIColor *> *_imageTintColors;
    NSMutableDictionary<NSNumber *, UIFont *> *_fonts;

    CGFloat _enabledAlpha;
    BOOL _hasCustomDisabledTitleColor;
    BOOL _imageTintStatefulAPIEnabled;

    // Cached accessibility settings.
    NSMutableDictionary<NSNumber *, NSString *> *_nontransformedTitles;
    NSString *_accessibilityLabelExplicitValue;

    BOOL _gtui_adjustsFontForContentSizeCategory;
}
@property(nonatomic, strong) GTUIInkView *inkView;
@property(nonatomic, readonly, strong) GTUIShapedShadowLayer *layer;
@end

@implementation GTUIButton


@dynamic layer;

+ (Class)layerClass {
    return [GTUIShapedShadowLayer class];
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Set up title label attributes.
        // TODO(#2709): Have a single source of truth for fonts
        // Migrate to [UIFont standardFont] when possible
        self.titleLabel.font = [GTUITypography buttonFont];

        [self commonGTUIButtonInit];
        [self updateBackgroundColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonGTUIButtonInit];

        if (self.titleLabel.font) {
            _fonts = [@{} mutableCopy];
            _fonts[@(UIControlStateNormal)] = self.titleLabel.font;
        }

        // Storyboards will set the backgroundColor via the UIView backgroundColor setter, so we have
        // to write that in to our _backgroundColors dictionary.
        _backgroundColors[@(UIControlStateNormal)] = self.layer.shapedBackgroundColor;
        [self updateBackgroundColor];
    }
    return self;
}

- (void)commonGTUIButtonInit {
    _disabledAlpha = GTUIButtonDisabledAlpha;
    _enabledAlpha = self.alpha;
    _uppercaseTitle = YES;
    _userElevations = [NSMutableDictionary dictionary];
    _nontransformedTitles = [NSMutableDictionary dictionary];
    _borderColors = [NSMutableDictionary dictionary];
    _imageTintColors = [NSMutableDictionary dictionary];
    _borderWidths = [NSMutableDictionary dictionary];
    _fonts = [NSMutableDictionary dictionary];
    _imageLocation = GTUIButtonImageLocationLeading;
    _imageTitleSpace = 8;

    if (!_backgroundColors) {
        // _backgroundColors may have already been initialized by setting the backgroundColor setter.
        _backgroundColors = [NSMutableDictionary dictionary];
        _backgroundColors[@(UIControlStateNormal)] = GTUIColorFromRGB(GTUIButtonDefaultBackgroundColor);
    }

    // Disable default highlight state.
    self.adjustsImageWhenHighlighted = NO;
    self.showsTouchWhenHighlighted = NO;

    // Default content insets
    self.contentEdgeInsets = [self defaultContentEdgeInsets];
    _minimumSize = CGSizeZero;
    _maximumSize = CGSizeZero;

    self.layer.cornerRadius = GTUIButtonDefaultCornerRadius;
    if (!self.layer.shapeGenerator) {
        self.layer.shadowPath = [self boundingPath].CGPath;
    }
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.elevation = [self elevationForState:self.state];

    _shadowColors = [NSMutableDictionary dictionary];
    _shadowColors[@(UIControlStateNormal)] = [UIColor colorWithCGColor:self.layer.shadowColor];

    // Set up ink layer.
    _inkView = [[GTUIInkView alloc] initWithFrame:self.bounds];
    _inkView.usesLegacyInkRipple = NO;
    [self insertSubview:_inkView belowSubview:self.imageView];
    // UIButton has a drag enter/exit boundary that is outside of the frame of the button itself.
    // Because this is not exposed externally, we can't use -touchesMoved: to calculate when to
    // change ink state. So instead we fall back on adding target/actions for these specific events.
    [self addTarget:self
             action:@selector(touchDragEnter:forEvent:)
   forControlEvents:UIControlEventTouchDragEnter];
    [self addTarget:self
             action:@selector(touchDragExit:forEvent:)
   forControlEvents:UIControlEventTouchDragExit];

    // Block users from activating multiple buttons simultaneously by default.
    self.exclusiveTouch = YES;

    _inkView.inkColor = [UIColor colorWithWhite:1 alpha:0.2f];

    // Uppercase all titles
    if (_uppercaseTitle) {
        [self updateTitleCase];
    }
}

- (void)dealloc {
    [self removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
}

- (void)setUnderlyingColorHint:(UIColor *)underlyingColorHint {
    _underlyingColorHint = underlyingColorHint;
    [self updateAlphaAndBackgroundColorAnimated:NO];
}

- (void)setAlpha:(CGFloat)alpha {
    if (self.enabled) {
        _enabledAlpha = alpha;
    }
    [super setAlpha:alpha];
}

- (void)setDisabledAlpha:(CGFloat)disabledAlpha {
    _disabledAlpha = disabledAlpha;
    [self updateAlphaAndBackgroundColorAnimated:NO];
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.layer.shapeGenerator) {
        self.layer.shadowPath = [self boundingPath].CGPath;
    }

    // Center unbounded ink view frame taking into account possible insets using contentRectForBounds.
    if (_inkView.inkStyle == GTUIInkStyleUnbounded && _inkView.usesLegacyInkRipple) {
        CGRect contentRect = [self contentRectForBounds:self.bounds];
        CGPoint contentCenterPoint =
        CGPointMake(CGRectGetMidX(contentRect), CGRectGetMidY(contentRect));
        CGPoint boundsCenterPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

        CGFloat offsetX = contentCenterPoint.x - boundsCenterPoint.x;
        CGFloat offsetY = contentCenterPoint.y - boundsCenterPoint.y;
        _inkView.frame = CGRectMake(offsetX, offsetY, self.bounds.size.width, self.bounds.size.height);
    } else {
        _inkView.frame = self.bounds;
    }


    // Position the imageView and titleView
    //
    // +------------------------------------+
    // |    |  |  |  CEI TOP            |   |
    // |CEI +--+  |+-----+              |CEI|
    // | LT ||SP||Title|              |RGT|
    // |    +--+  |+-----+              |   |
    // |    |  |  |  CEI BOT            |   |
    // +------------------------------------+
    //
    // (A) The same spacing on either side of the label.
    // (SP) The spacing between the image and title
    // (CEI) Content Edge Insets
    //
    // The diagram above assumes an LTR user interface orientation
    // and a .leadingIcon imageLocation for this button.

    CGFloat imageWith = self.imageView.image.size.width;
    CGFloat imageHeight = self.imageView.image.size.height;
    CGFloat spacing = self.imageTitleSpace;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGFloat labelWidth = [self.titleLabel.text sizeWithFont:self.titleLabel.font].width;
    CGFloat labelHeight = [self.titleLabel.text sizeWithFont:self.titleLabel.font].height;
#pragma clang diagnostic pop
    CGFloat imageOffsetX = (imageWith + labelWidth) / 2 - imageWith / 2;//image中心移动的x距离
    CGFloat imageOffsetY = imageHeight / 2 + spacing / 2;//image中心移动的y距离
    CGFloat labelOffsetX = (imageWith + labelWidth / 2) - (imageWith + labelWidth) / 2;//label中心移动的x距离
    CGFloat labelOffsetY = labelHeight / 2 + spacing / 2;//label中心移动的y距离

    switch (self.imageLocation) {
        case GTUIButtonImageLocationLeading:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, -spacing/2, 0, spacing/2);
            self.titleEdgeInsets = UIEdgeInsetsMake(0, spacing/2, 0, -spacing/2);
            break;
        case GTUIButtonImageLocationTrailing:
            self.imageEdgeInsets = UIEdgeInsetsMake(0, labelWidth + spacing/2, 0, -(labelWidth + spacing/2));
            self.titleEdgeInsets = UIEdgeInsetsMake(0, -(imageHeight + spacing/2), 0, imageHeight + spacing/2);
            break;
        case GTUIButtonImageLocationTop:
            self.imageEdgeInsets = UIEdgeInsetsMake(-imageOffsetY, imageOffsetX, imageOffsetY, -imageOffsetX);
            self.titleEdgeInsets = UIEdgeInsetsMake(labelOffsetY, -labelOffsetX, -labelOffsetY, labelOffsetX);
            break;
        case GTUIButtonImageLocationBottom:
            self.imageEdgeInsets = UIEdgeInsetsMake(imageOffsetY, imageOffsetX, -imageOffsetY, -imageOffsetX);
            self.titleEdgeInsets = UIEdgeInsetsMake(-labelOffsetY, -labelOffsetX, labelOffsetY, labelOffsetX);
            break;
        default:
            break;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // If there are custom hitAreaInsets, use those
    if (!UIEdgeInsetsEqualToEdgeInsets(self.hitAreaInsets, UIEdgeInsetsZero)) {
        return CGRectContainsPoint(
                                   UIEdgeInsetsInsetRect(CGRectStandardize(self.bounds), self.hitAreaInsets), point);
    }

    // If the bounds are smaller than the minimum touch target, produce a warning once
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    if (width < GTUIButtonMinimumTouchTargetWidth || height < GTUIButtonMinimumTouchTargetHeight) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(
                  @"Button touch target does not meet minimum size guidlines of (%0.f, %0.f). Button: %@, "
                  @"Touch Target: %@",
                  GTUIButtonMinimumTouchTargetWidth,
                  GTUIButtonMinimumTouchTargetHeight,
                  [self description],
                  NSStringFromCGSize(CGSizeMake(width, height)));
        });
    }
    return [super pointInside:point withEvent:event];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self.inkView cancelAllAnimationsAnimated:NO];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize superSize = [super sizeThatFits:size];

    if (CGSizeEqualToSize(self.bounds.size, size)) {
        size = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    }

    if (self.minimumSize.height > 0) {
        superSize.height = MAX(self.minimumSize.height, superSize.height);
    }
    if (self.maximumSize.height > 0) {
        superSize.height = MIN(self.maximumSize.height, superSize.height);
    }
    if (self.minimumSize.width > 0) {
        superSize.width = MAX(self.minimumSize.width, superSize.width);
    }
    if (self.maximumSize.width > 0) {
        superSize.width = MIN(self.maximumSize.width, superSize.width);
    }

    [self.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

    return superSize;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    [self handleBeginTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    // Drag events handled by -touchDragExit:forEvent: and -touchDragEnter:forEvent:
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    CGPoint location = [self locationFromTouches:touches];
    [_inkView startTouchEndedAnimationAtPoint:location completion:nil];
}

// Note - in some cases, event may be nil (e.g. view removed from window).
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];

    [self evaporateInkToPoint:[self locationFromTouches:touches]];
}

#pragma mark - UIControl methods

- (void)setEnabled:(BOOL)enabled {
    [self setEnabled:enabled animated:NO];
}

- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated {
    [super setEnabled:enabled];

    [self updateAfterStateChange:animated];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    [self updateAfterStateChange:NO];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    [self updateAfterStateChange:NO];
}

- (void)updateAfterStateChange:(BOOL)animated {
    [self updateAlphaAndBackgroundColorAnimated:animated];
    [self animateButtonToHeightForState:self.state];
    [self updateBorderColor];
    [self updateBorderWidth];
    [self updateShadowColor];
    [self updateTitleFont];
    [self updateImageTintColor];
}

#pragma mark - Title Uppercasing

- (void)setUppercaseTitle:(BOOL)uppercaseTitle {
    _uppercaseTitle = uppercaseTitle;

    [self updateTitleCase];
}

- (void)updateTitleCase {
    // This calls setTitle or setAttributedTitle for every title value we have stored. In each
    // respective setter the title is upcased if _uppercaseTitle is YES.
    NSDictionary<NSNumber *, NSString *> *nontransformedTitles = [_nontransformedTitles copy];
    for (NSNumber *key in nontransformedTitles.keyEnumerator) {
        UIControlState state = key.unsignedIntegerValue;
        NSString *title = nontransformedTitles[key];
        if ([title isKindOfClass:[NSAttributedString class]]) {
            [self setAttributedTitle:(NSAttributedString *)title forState:state];
        } else {
            [self setTitle:title forState:state];
        }
    }
}

- (void)updateShadowColor {
    self.layer.shadowColor = [self shadowColorForState:self.state].CGColor;
}

- (void)setShadowColor:(UIColor *)shadowColor forState:(UIControlState)state {
    if (shadowColor) {
        _shadowColors[@(state)] = shadowColor;
    } else {
        [_shadowColors removeObjectForKey:@(state)];
    }

    if (state == self.state) {
        [self updateShadowColor];
    }
}

- (UIColor *)shadowColorForState:(UIControlState)state {
    UIColor *shadowColor = _shadowColors[@(state)];
    if (state != UIControlStateNormal && !shadowColor) {
        shadowColor = _shadowColors[@(UIControlStateNormal)];
    }
    return shadowColor;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    // Intercept any setting of the title and store a copy in case the accessibilityLabel
    // is requested and the original non-uppercased version needs to be returned.
    if ([title length]) {
        _nontransformedTitles[@(state)] = [title copy];
    } else {
        [_nontransformedTitles removeObjectForKey:@(state)];
    }

    if (_uppercaseTitle) {
        title = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    [super setTitle:title forState:state];
}

- (void)setAttributedTitle:(NSAttributedString *)title forState:(UIControlState)state {
    // Intercept any setting of the title and store a copy in case the accessibilityLabel
    // is requested and the original non-uppercased version needs to be returned.
    if ([title length]) {
        _nontransformedTitles[@(state)] = [[title string] copy];
    } else {
        [_nontransformedTitles removeObjectForKey:@(state)];
    }

    if (_uppercaseTitle) {
        title = uppercaseAttributedString(title);
    }
    [super setAttributedTitle:title forState:state];
}

#pragma mark - Accessibility

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel {
    // Intercept any explicit setting of the accessibilityLabel so it can be returned
    // later before the accessibiilityLabel is inferred from the setTitle:forState:
    // argument values.
    _accessibilityLabelExplicitValue = [accessibilityLabel copy];
    [super setAccessibilityLabel:accessibilityLabel];
}

- (NSString *)accessibilityLabel {
    if (!_uppercaseTitle) {
        return [super accessibilityLabel];
    }

    NSString *label = _accessibilityLabelExplicitValue;
    if ([label length]) {
        return label;
    }

    label = _nontransformedTitles[@(self.state)];
    if ([label length]) {
        return label;
    }

    label = _nontransformedTitles[@(UIControlStateNormal)];
    if ([label length]) {
        return label;
    }

    label = [super accessibilityLabel];
    if ([label length]) {
        return label;
    }

    return nil;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return [super accessibilityTraits] | UIAccessibilityTraitButton;
}

#pragma mark - Ink

- (GTUIInkStyle)inkStyle {
    return _inkView.inkStyle;
}

- (void)setInkStyle:(GTUIInkStyle)inkStyle {
    _inkView.inkStyle = inkStyle;
}

- (UIColor *)inkColor {
    return _inkView.inkColor;
}

- (void)setInkColor:(UIColor *)inkColor {
    _inkView.inkColor = inkColor;
}

- (CGFloat)inkMaxRippleRadius {
    return _inkView.maxRippleRadius;
}

- (void)setInkMaxRippleRadius:(CGFloat)inkMaxRippleRadius {
    _inkView.maxRippleRadius = inkMaxRippleRadius;
}

#pragma mark - Shadows

- (void)animateButtonToHeightForState:(UIControlState)state {
    CGFloat newElevation = [self elevationForState:state];
    if (self.layer.elevation == newElevation) {
        return;
    }
    [CATransaction begin];
    [CATransaction setAnimationDuration:GTUIButtonAnimationDuration];
    self.layer.elevation = newElevation;
    [CATransaction commit];
}

#pragma mark - BackgroundColor

- (void)setBackgroundColor:(nullable UIColor *)backgroundColor {
    // Since setBackgroundColor can be called in the initializer we need to optionally build the dict.
    if (!_backgroundColors) {
        _backgroundColors = [NSMutableDictionary dictionary];
    }
    _backgroundColors[@(UIControlStateNormal)] = backgroundColor;
    [self updateBackgroundColor];
}

- (UIColor *)backgroundColor {
    return self.layer.shapedBackgroundColor;
}

- (UIColor *)backgroundColorForState:(UIControlState)state {
    return _backgroundColors[@(state)];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    _backgroundColors[@(state)] = backgroundColor;
    [self updateAlphaAndBackgroundColorAnimated:NO];
}

#pragma mark - Image Tint Color

- (nullable UIColor *)imageTintColorForState:(UIControlState)state {

    return _imageTintColors[@(state)] ?: _imageTintColors[@(UIControlStateNormal)];
}

- (void)setImageTintColor:(nullable UIColor *)imageTintColor forState:(UIControlState)state {
    _imageTintColors[@(state)] = imageTintColor;
    _imageTintStatefulAPIEnabled = YES;
    [self updateImageTintColor];
}

- (void)updateImageTintColor {
    if (!_imageTintStatefulAPIEnabled) {
        return;
    }
    self.imageView.tintColor = [self imageTintColorForState:self.state];
}

#pragma mark - Elevations

- (CGFloat)elevationForState:(UIControlState)state {
    NSNumber *elevation = _userElevations[@(state)];
    if (state != UIControlStateNormal && (elevation == nil)) {
        elevation = _userElevations[@(UIControlStateNormal)];
    }
    if (elevation != nil) {
        return (CGFloat)[elevation doubleValue];
    }
    return 0;
}

- (void)setElevation:(CGFloat)elevation forState:(UIControlState)state {
    _userElevations[@(state)] = @(elevation);
    GTUIShadowElevation newElevation = [self elevationForState:self.state];
    // If no change to the current elevation, don't perform updates
    if (GTUICGFloatEqual(newElevation, self.layer.elevation)) {
        return;
    }
    self.layer.elevation = newElevation;

    // The elevation of the normal state controls whether this button is flat or not, and flat buttons
    // have different background color requirements than raised buttons.
    // TODO(ajsecord): Move to GTUIFlatButton and update this comment.
    if (state == UIControlStateNormal) {
        [self updateAlphaAndBackgroundColorAnimated:NO];
    }
}

#pragma mark - Border Color

- (UIColor *)borderColorForState:(UIControlState)state {
    return _borderColors[@(state)];
}

- (void)setBorderColor:(UIColor *)borderColor forState:(UIControlState)state {
    _borderColors[@(state)] = borderColor;

    [self updateBorderColor];
}

#pragma mark - Border Width

- (CGFloat)borderWidthForState:(UIControlState)state {
    NSNumber *borderWidth = _borderWidths[@(state)];
    if (borderWidth != nil) {
        return (CGFloat)borderWidth.doubleValue;
    }
    return 0;
}

- (void)setBorderWidth:(CGFloat)borderWidth forState:(UIControlState)state {
    _borderWidths[@(state)] = @(borderWidth);

    [self updateBorderWidth];
}

- (void)updateBorderWidth {
    NSNumber *width = _borderWidths[@(self.state)];
    if ((width == nil) && self.state != UIControlStateNormal) {
        // We fall back to UIControlStateNormal if there is no value for the current state.
        width = _borderWidths[@(UIControlStateNormal)];
    }
    self.layer.shapedBorderWidth = (width != nil) ? (CGFloat)width.doubleValue : 0;
}

#pragma mark - Title Font

- (nullable UIFont *)titleFontForState:(UIControlState)state {
    return _fonts[@(state)];
}

- (void)setTitleFont:(nullable UIFont *)font forState:(UIControlState)state {
    _fonts[@(state)] = font;

    [self updateTitleFont];
}

#pragma mark - Private methods

- (UIColor *)currentBackgroundColor {
    UIColor *color = _backgroundColors[@(self.state)];
    if (color) {
        return color;
    }
    return [self backgroundColorForState:UIControlStateNormal];
}

/**
 The background color that a user would see for this button. If self.backgroundColor is not
 transparent, then returns that. Otherwise, returns self.underlyingColorHint.
 @note If self.underlyingColorHint is not set, then this method will return nil.
 */
- (UIColor *)effectiveBackgroundColor {
    if (![self isTransparentColor:self.currentBackgroundColor]) {
        return self.currentBackgroundColor;
    } else {
        return self.underlyingColorHint;
    }
}

/** Returns YES if the color is not transparent and is a "dark" color. */
- (BOOL)isDarkColor:(UIColor *)color {
    // TODO: have a components/private/ColorCalculations/GTUIColorCalculations.h|m
    //  return ![self isTransparentColor:color] && [QTMColorGroup luminanceOfColor:color] < 0.5f;
    return ![self isTransparentColor:color];
}

/** Returns YES if the color is transparent (including a nil color). */
- (BOOL)isTransparentColor:(UIColor *)color {
    return !color || [color isEqual:[UIColor clearColor]] || CGColorGetAlpha(color.CGColor) == 0.0f;
}

- (void)touchDragEnter:(__unused GTUIButton *)button forEvent:(UIEvent *)event {
    [self handleBeginTouches:event.allTouches];
}

- (void)touchDragExit:(__unused GTUIButton *)button forEvent:(UIEvent *)event {
    CGPoint location = [self locationFromTouches:event.allTouches];
    [self evaporateInkToPoint:location];
}

- (void)handleBeginTouches:(NSSet *)touches {
    [_inkView startTouchBeganAnimationAtPoint:[self locationFromTouches:touches] completion:nil];
}

- (CGPoint)locationFromTouches:(NSSet *)touches {
    UITouch *touch = [touches anyObject];
    return [touch locationInView:self];
}

- (void)evaporateInkToPoint:(CGPoint)toPoint {
    [_inkView startTouchEndedAnimationAtPoint:toPoint completion:nil];
}

- (UIBezierPath *)boundingPath {
    CGFloat cornerRadius = self.layer.cornerRadius;
    return [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius];
}

- (UIEdgeInsets)defaultContentEdgeInsets {
    return UIEdgeInsetsMake(8, 16, 8, 16);
}

- (BOOL)shouldHaveOpaqueBackground {
    BOOL isFlatButton = GTUICGFloatIsExactlyZero([self elevationForState:UIControlStateNormal]);
    return !isFlatButton;
}

- (void)updateAlphaAndBackgroundColorAnimated:(BOOL)animated {
    void (^animations)(void) = ^{
        self.alpha = self.enabled ? self->_enabledAlpha : self.disabledAlpha;
        [self updateBackgroundColor];
    };

    if (animated) {
        [UIView animateWithDuration:GTUIButtonAnimationDuration animations:animations];
    } else {
        animations();
    }
}

- (void)updateBackgroundColor {
    // When shapeGenerator is unset then self.layer.shapedBackgroundColor sets the layer's
    // backgroundColor. Whereas when shapeGenerator is set the sublayer's fillColor is set.
    self.layer.shapedBackgroundColor = self.currentBackgroundColor;
    [self updateDisabledTitleColor];
}

- (void)updateDisabledTitleColor {
    // We only want to automatically set a disabled title color if the user hasn't already provided a
    // value.
    if (_hasCustomDisabledTitleColor) {
        return;
    }
    // Disabled buttons have very low opacity, so we full-opacity text color here to make the text
    // readable. Also, even for non-flat buttons with opaque backgrounds, the correct background color
    // to examine is the underlying color, since disabled buttons are so transparent.
    BOOL darkBackground = [self isDarkColor:[self underlyingColorHint]];
    // We call super here to distinguish between automatic title color assignments and that of users.
    [super setTitleColor:darkBackground ? [UIColor whiteColor] : [UIColor blackColor]
                forState:UIControlStateDisabled];
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state {
    [super setTitleColor:color forState:state];
    if (state == UIControlStateDisabled) {
        _hasCustomDisabledTitleColor = color != nil;
        if (!_hasCustomDisabledTitleColor) {
            [self updateDisabledTitleColor];
        }
    }
}

- (void)updateBorderColor {
    UIColor *color = _borderColors[@(self.state)];
    if (!color && self.state != UIControlStateNormal) {
        // We fall back to UIControlStateNormal if there is no value for the current state.
        color = _borderColors[@(UIControlStateNormal)];
    }
    self.layer.shapedBorderColor = color ?: NULL;
}

- (void)updateTitleFont {
    // Retreive any custom font that has been set
    UIFont *font = _fonts[@(self.state)];
    if (!font && self.state != UIControlStateNormal) {
        // We fall back to UIControlStateNormal if there is no value for the current state.
        font = _fonts[@(UIControlStateNormal)];
    }

    if (!font) {
        // TODO(#2709): Have a single source of truth for fonts
        // Migrate to [UIFont standardFont] when possible
        font = [GTUITypography  buttonFont];
    }

    if (_gtui_adjustsFontForContentSizeCategory) {
        // Dynamic type is enabled so apply scaling
        font = [font gtui_fontSizedForFontTextStyle:GTUIFontTextStyleButton scaledForDynamicType:YES];
    }

    self.titleLabel.font = font;

    [self setNeedsLayout];
}

- (void)setShapeGenerator:(id<GTUIShapeGenerating>)shapeGenerator {
    if (shapeGenerator) {
        self.layer.shadowPath = nil;
    } else {
        self.layer.shadowPath = [self boundingPath].CGPath;
    }
    self.layer.shapeGenerator = shapeGenerator;
    // The imageView is added very early in the lifecycle of a UIButton, therefore we need to move
    // the colorLayer behind the imageView otherwise the image will not show.
    // Because the inkView needs to go below the imageView, but above the colorLayer
    // we need to have the colorLayer be at the back
    [self.layer.colorLayer removeFromSuperlayer];
    [self.layer insertSublayer:self.layer.colorLayer below:self.inkView.layer];
    [self updateBackgroundColor];
    [self updateInkForShape];
}

- (id<GTUIShapeGenerating>)shapeGenerator {
    return self.layer.shapeGenerator;
}

- (void)updateInkForShape {
    CGRect boundingBox = CGPathGetBoundingBox(self.layer.shapeLayer.path);
    self.inkView.maxRippleRadius =
    (CGFloat)(GTUIHypot(CGRectGetHeight(boundingBox), CGRectGetWidth(boundingBox)) / 2 + 10.f);
    self.inkView.layer.masksToBounds = NO;
}

#pragma mark - Dynamic Type

- (BOOL)gtui_adjustsFontForContentSizeCategory {
    return _gtui_adjustsFontForContentSizeCategory;
}

- (void)gtui_setAdjustsFontForContentSizeCategory:(BOOL)adjusts {
    _gtui_adjustsFontForContentSizeCategory = adjusts;
    if (_gtui_adjustsFontForContentSizeCategory) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryDidChange:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIContentSizeCategoryDidChangeNotification
                                                      object:nil];
    }

    [self updateTitleFont];
}

- (void)contentSizeCategoryDidChange:(__unused NSNotification *)notification {
    [self updateTitleFont];

    [self sizeToFit];
}

@end
