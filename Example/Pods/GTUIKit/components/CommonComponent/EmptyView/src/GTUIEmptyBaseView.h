//
//  GTUIEmptyBaseView.h
//  GTCatalog
//
//  Created by liuxc on 2018/11/30.
//

#import <UIKit/UIKit.h>

/** 事件回调  */
typedef void (^GTUIActionTapBlock)(void);

@interface GTUIEmptyBaseView : UIView

/**  内容物背景视图 */
@property (nonatomic,strong,readonly) UIView *contentView;

/** 属性传递(可修改) */
@property (nonatomic, copy) UIImage *image;
@property (nonatomic, copy) NSString *imageStr;
@property (nonatomic, copy) NSString *titleStr;
@property (nonatomic, copy) NSString *detailStr;
@property (nonatomic, copy) NSString *btnTitleStr;
@property (nonatomic, copy) GTUIActionTapBlock tapContentViewBlock;

/** 属性传递 (这些属性只用来传递，修改无效) */
@property (nonatomic, weak, readonly)   id actionBtnTarget;
@property (nonatomic,assign,readonly)   SEL actionBtnAction;
@property (nonatomic, copy, readonly)   GTUIActionTapBlock btnClickBlock;
@property (nonatomic,strong,readonly)   UIView *customView;

/** 是否自动显隐EmptyView, default=YES */
@property (nonatomic, assign) BOOL autoShowEmptyView;

/** 初始化配置 */
- (void)prepare;

/** 重置Subviews */
- (void)setupSubviews;


/**
 构造方法1 - 创建emptyView

 @param imageStr    占位图片名称
 @param titleStr    标题
 @param detailStr   详细描述
 @param btnTitleStr 按钮的名称
 @param target      响应的对象
 @param action      按钮点击事件
 @return 返回一个emptyView
 */
+ (instancetype)emptyActionViewWithImageStr:(NSString *)imageStr
                                   titleStr:(NSString *)titleStr
                                  detailStr:(NSString *)detailStr
                                btnTitleStr:(NSString *)btnTitleStr
                                     target:(id)target
                                     action:(SEL)action;

/**
 构造方法2 - 创建emptyView

 @param imageStr       占位图片名称
 @param titleStr       占位描述
 @param detailStr      详细描述
 @param btnTitleStr    按钮的名称
 @param btnClickBlock  按钮点击事件回调
 @return 返回一个emptyView
 */
+ (instancetype)emptyActionViewWithImageStr:(NSString *)imageStr
                                   titleStr:(NSString *)titleStr
                                  detailStr:(NSString *)detailStr
                                btnTitleStr:(NSString *)btnTitleStr
                              btnClickBlock:(GTUIActionTapBlock)btnClickBlock;

/**
 构造方法3 - 创建emptyView

 @param imageStr      占位图片名称
 @param titleStr      占位描述
 @param detailStr     详细描述
 @return 返回一个没有点击事件的emptyView
 */
+ (instancetype)emptyViewWithImageStr:(NSString *)imageStr
                             titleStr:(NSString *)titleStr
                            detailStr:(NSString *)detailStr;


/**
 构造方法4 - 创建emptyView

 @param image       image图片对象
 @param titleStr    标题
 @param detailStr   详细描述
 @param btnTitleStr 按钮的名称
 @param target      响应的对象
 @param action      按钮点击事件
 @return 返回一个emptyView
 */
+ (instancetype)emptyActionViewWithImage:(UIImage *)image
                                titleStr:(NSString *)titleStr
                               detailStr:(NSString *)detailStr
                             btnTitleStr:(NSString *)btnTitleStr
                                  target:(id)target
                                  action:(SEL)action;

/**
 构造方法2 - 创建emptyView

 @param image          image图片对象
 @param titleStr       占位描述
 @param detailStr      详细描述
 @param btnTitleStr    按钮的名称
 @param btnClickBlock  按钮点击事件回调
 @return 返回一个emptyView
 */
+ (instancetype)emptyActionViewWithImage:(UIImage *)image
                                   titleStr:(NSString *)titleStr
                                  detailStr:(NSString *)detailStr
                                btnTitleStr:(NSString *)btnTitleStr
                              btnClickBlock:(GTUIActionTapBlock)btnClickBlock;

/**
 构造方法5 - 创建一个自定义的emptyView

 @param customView 自定义view
 @return 返回一个自定义内容的emptyView
 */
+ (instancetype)emptyViewWithCustomView:(UIView *)customView;

@end
