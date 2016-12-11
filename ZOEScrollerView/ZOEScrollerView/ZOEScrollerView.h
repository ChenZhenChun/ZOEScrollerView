//
//  ZOEScrollerView.h
//  AiyoyouCocoapods
//  description 广告图片无限轮翻
//  Created by aiyoyou on 16/1/5.
//  Copyright © 2016年 zoenet. All rights reserved.

/**
[timer invalidate];//失效
[timer setFireDate:[NSDate date]];//继续
[timer setFireDate:[NSDate distantFuture]];//暂停
*/

#import <UIKit/UIKit.h>
@class ZOEScrollerView;

@protocol ZOEScrollerViewDelegate <NSObject>
@required
/**
 数据源个数

 @return 个数
 */
- (NSInteger)numberOfPageSize;

/**
 图片渲染（对imageView赋值图片）
 @param scrollerView 控件本身实例对象
 @param imageView 图片容器
 @param pageIndex 图片索引
 */
- (void)scrollerView:(ZOEScrollerView *)scrollerView imageView:(UIImageView *)imageView configImageForPageInIndex:(NSInteger)pageIndex;

@optional
/**
 图片左下角文字简介（对noteTitleLabel赋值文本）

 @param scrollerView 控件本书实例对象
 @param noteTitleLabel 文字label对象
 @param pageIndex 文字索引
 */
- (void)scrollerView:(ZOEScrollerView *)scrollerView noteTitle:(UILabel *)noteTitleLabel configTitleForPageInIndex:(NSInteger)pageIndex;

/**
 控件点击事件

 @param scrollerView 控件本身实例对象
 @param pageIndex 图片索引
 */
- (void)scrollerView:(ZOEScrollerView *)scrollerView didSelectedInIndex:(NSInteger)pageIndex;
@end

@interface ZOEScrollerView : UIView
@property (assign,nonatomic,readonly) NSTimer            *timer;//扩展字段，一般不需要用到
@property (assign,nonatomic) NSTimeInterval              timeInterva;//动画间隔 Default 3.0
@property (nonatomic,assign) id<ZOEScrollerViewDelegate> delegate;

/**
 数据源改变刷新控件
 */
- (void)reloadData;
@end
