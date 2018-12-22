//
//  GTUIGrid.h
//  GTUILayout
//
//  Created by liuxc on 2018/12/2.
//  Copyright © 2018 liuxc. All rights reserved.
//

#import "GTUILayoutDefine.h"
#import "GTUIBorderline.h"

/**
 *  定义格式化栅格描述语言的key和对应的value。这些值可以用来设置栅格布局的gridDictionary属性中字典的各种键值对。
 */
extern NSString * const kGTUIGridTag;      //NSNumber类型，设置栅格的标签，对应GTUIGrid的tag属性。 具体值为NSInteger
extern NSString * const kGTUIGridAction;   //NSString类型，设置栅格的触摸动作，对应GTUIGrid的setTarget中的action参数。
extern NSString * const kGTUIGridActionData;  //id类型， 设置栅格的动作数据，对应GTUIGrid的actionData属性。
extern NSString * const kGTUIGridRows;    //NSArray<NSDictionary>类型，表示里面的值是行子栅格数组.数组的元素是一个个子栅格字典对象
extern NSString * const kGTUIGridCols;    //NSArray<NSDictionary>类型，表示里面的值是列子栅格数组.数组的元素是一个个子栅格字典对象
extern NSString * const kGTUIGridSize;    //NSString类型或者NSNumber类型。设置栅格的尺寸，可以为特定的值vGTUIGridSizeWrap或者vGTUIGridSizeFill，也可以为某个具体的数字比如20.0, 还可以为百分比数字比如：@"20%" 或者@"-20%"。
extern NSString * const kGTUIGridPadding;  //NSString类型，设置栅格的内边距，对应GTUIGrid的padding属性，具体的值的格式为：@"{上,左,下,右}"
extern NSString * const kGTUIGridSpace;    //NSNumber类型，栅格的内子栅格的间距，对应GTUIGrid的subviewSpace属性。
extern NSString * const kGTUIGridGravity;   //NSString类型，栅格的停靠属性，对应GTUIGrid的gravity属性，具体的值请参考下面的定义，比如：@"top|left"
extern NSString * const kGTUIGridPlaceholder;  //NSNumber类型，栅格的占位属性，对应GTUIGrid的placeholder 属性，具体的值设置为YES or NO
extern NSString * const kGTUIGridAnchor;      //NSNumber类型，栅格的锚点属性，对应GTUIGrid的anchor属性，具体的值设置为YES or NO
extern NSString * const kGTUIGridOverlap;    //NSString类型,重叠视图停靠属性，对应GTUIGrid的gravity属性，具体的值请参考下面的定义，比如：@"top|left"
extern NSString * const kGTUIGridTopBorderline;   //NSDictionary类型 栅格的顶部边界线对象。
extern NSString * const kGTUIGridBottomBorderline; //NSDictionary类型 栅格的底部边界线对象。
extern NSString * const kGTUIGridLeftBorderline;   //NSDictionary类型 栅格的左边边界线对象。
extern NSString * const kGTUIGridRightBorderline;  //NSDictionary类型 栅格的右边边界线对象。

//栅格的边界线对象所能设置的key
extern NSString * const kGTUIGridBorderlineColor;  //NSString类型，用字符串格式描述的颜色值。具体为：@"#FF0000" 表示红色
extern NSString * const kGTUIGridBorderlineThick;   //NSNumber类型， 边界线的粗细
extern NSString * const kGTUIGridBorderlineHeadIndent;  //NSNumber类型，边界线的头部缩进值
extern NSString * const kGTUIGridBorderlineTailIndent;   //NSNumber类型，边界线的尾部缩进值。
extern NSString * const kGTUIGridBorderlineOffset;       //NSNumber类型，边界线的偏移值。
extern NSString * const kGTUIGridBorderlineDash;       //NSNumber类型，边界线是虚线。


//kGTUIGridSize可以设置的特殊值
extern NSString * const vGTUIGridSizeWrap;    //表示尺寸由子栅格决定。
extern NSString * const vGTUIGridSizeFill;    //表示尺寸填充父栅格的剩余部分

//kGTUIGridGravity可以设置的值
extern NSString * const vGTUIGridGravityTop;     //对应GTUIGravityVertTop
extern NSString * const vGTUIGridGravityBottom;  //对应GTUIGravityVertBottom
extern NSString * const vGTUIGridGravityLeft;    //对应GTUIGravityHorzLeft
extern NSString * const vGTUIGridGravityRight;   //对应GTUIGravityHorzRight
extern NSString * const vGTUIGridGravityLeading;  //对应GTUIGravityHorzLeading
extern NSString * const vGTUIGridGravityTrailing; //对应GTUIGravityHorzTrailing
extern NSString * const vGTUIGridGravityCenterX;  //对应GTUIGravityHorzCenterX
extern NSString * const vGTUIGridGravityCenterY;  //对应GTUIGravityVertCenterY
extern NSString * const vGTUIGridGravityWidthFill;  //对应GTUIGravityHorzFill
extern NSString * const vGTUIGridGravityHeightFill;  //对应GTUIGravityVertFill


/**
 栅格动作接口，您可以触摸栅格来执行特定的动作和事件。
 */
@protocol GTUIGridAction<NSObject>


/**
 栅格的标签标识，用于在事件中区分栅格。
 */
@property(nonatomic)  NSInteger tag;


/**
 栅格的动作数据，这个数据是栅格的扩展数据，您可以在动作中使用这个附加的数据来进行一系列操作。他可以是一个数值，也可以是个字符串，甚至可以是一段JS脚本。
 */
@property(nonatomic, strong) id actionData;



/**
 设置栅格的事件,如果取消栅格事件则设置target为nil
 
 @param target action事件的调用者
 @param action action事件，格式为：-(void)handle:(id<GTUIGrid>)sender
 */
-(void)setTarget:(id)target action:(SEL)action;

@end




/**
 栅格协议。用来描述栅格矩形区域，所以一个栅格就是一个矩形区域。 这个接口用来描述栅格的一些属性以及栅格的添加和删除。栅格可以按某个方向拆分为众多子栅格，而且这个过程可以递归进行。
 所有栅格布局中的子视图都将依次放入叶子栅格的区域中。
 */
@protocol GTUIGrid <GTUIGridAction>


//设置和获取栅格的尺寸
@property(nonatomic, assign) CGFloat measure;


//得到父栅格。根栅格的父栅格为nil
@property(nonatomic, weak, readonly) id<GTUIGrid> superGrid;


/**
 得到所有子栅格
 */
@property(nonatomic, strong, readonly) NSArray<id<GTUIGrid>> *subGrids;


/**
 克隆出一个新栅格以及其下的所有子栅格。
 */
-(id<GTUIGrid>)cloneGrid;


/**
 栅格内子栅格之间的间距。
 */
@property(nonatomic, assign) CGFloat subviewSpace;

/**
 栅格内子栅格或者叶子栅格内视图的四周内边距。
 */
@property(nonatomic, assign) UIEdgeInsets padding;


/**
 栅格内子栅格或者叶子栅格内视图的对齐停靠方式.
 
 1.对于非叶子栅格来说只能设置一个方向的停靠。具体只能设置左中右或者上中下
 2.对于叶子栅格来说，如果设置了gravity 则填充的子视图必须要设置明确的尺寸。
 */
@property(nonatomic, assign) GTUIGravity gravity;

/**
 占位标志，只用叶子栅格，当设置为YES时则表示这个格子只用于占位，子视图不能填充到这个栅格中。
 */
@property(nonatomic, assign) BOOL placeholder;


/**
 锚点标志，表示这个栅格虽然是非叶子栅格，也可以用来填充视图。如果将非叶子栅格的锚点标志设置为YES，那么这个栅格也可以用来填充子视图，一般用来当做背景视图使用。
 */
@property(nonatomic, assign) BOOL anchor;

/**
 重叠视图的对齐停靠方式
 对于叶子栅格来说,如果设置了gravity 则填充的子视图必须要设置明确的尺寸
 */
@property(nonatomic, assign) GTUIGravity overlap;


/**顶部边界线*/
@property(nonatomic, strong) GTUIBorderline *topBorderline;
/**头部边界线*/
@property(nonatomic, strong) GTUIBorderline *leadingBorderline;
/**底部边界线*/
@property(nonatomic, strong) GTUIBorderline *bottomBorderline;
/**尾部边界线*/
@property(nonatomic, strong) GTUIBorderline *trailingBorderline;

/**如果您不需要考虑国际化的问题则请用这个属性设置左边边界线，否则用leadingBorderline*/
@property(nonatomic, strong) GTUIBorderline *leftBorderline;
/**如果您不需要考虑国际化的问题则请用这个属性设置右边边界线，否则用trailingBorderline*/
@property(nonatomic, strong) GTUIBorderline *rightBorderline;



/**
 添加行栅格，返回新的栅格。其中的measure可以设置如下的值：
 1.大于等于1的常数，表示固定尺寸。
 2.大于0小于1的常数，表示占用整体尺寸的比例
 3.小于0大于-1的常数，表示占用剩余尺寸的比例
 4.GTUILayoutSize.wrap 表示尺寸由子栅格包裹
 5.GTUILayoutSize.fill 表示占用栅格剩余的尺寸
 */
-(id<GTUIGrid>)addRow:(CGFloat)measure;

/**
 添加列栅格，返回新的栅格。其中的measure可以设置如下的值：
 1.大于等于1的常数，表示固定尺寸。
 2.大于0小于1的常数，表示占用整体尺寸的比例
 3.小于0大于-1的常数，表示占用剩余尺寸的比例
 4.GTUILayoutSize.wrap 表示尺寸由子栅格包裹
 5.GTUILayoutSize.fill 表示占用栅格剩余的尺寸
 */
-(id<GTUIGrid>)addCol:(CGFloat)measure;

//添加栅格，返回被添加的栅格。这个方法和下面的cloneGrid配合使用可以用来构建那些需要重复添加栅格的场景。
-(id<GTUIGrid>)addRowGrid:(id<GTUIGrid>)grid;
-(id<GTUIGrid>)addColGrid:(id<GTUIGrid>)grid;

-(id<GTUIGrid>)addRowGrid:(id<GTUIGrid>)grid measure:(CGFloat)measure;
-(id<GTUIGrid>)addColGrid:(id<GTUIGrid>)grid measure:(CGFloat)measure;


//从父栅格中删除。
-(void)removeFromSuperGrid;


//用字典的方式来构造栅格。
@property(nonatomic, strong) NSDictionary *gridDictionary;

@end


@interface UIColor (GTUIGrid)

/**
 从十六进制或者系统自带字符串创建并返回一个颜色对象
 
 @discussion:
 Valid format: #RRGGBB #RRGGBBAA red blue .....
 
 
 Example: @"#66CCFF", @"#66CCFF88" , @"red" , @"blue"
 
 @param hexString  颜色值
 
 @return        来自字符串的UIColor对象，如果发生错误，则为nil
 */
+ ( UIColor *)gtuiColorWithHexString:(NSString *)hexString;


/**
 RGB 颜色值
 @return 十六进制格式的字符串颜色，参考上面的hexStr入参。
 */
- (NSString *)gtuiHexString;

@end



