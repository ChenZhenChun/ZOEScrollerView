//
//  ZOEScrollerView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 16/1/5.
//  Copyright © 2016年 zoenet. All rights reserved.
//

#import "ZOEScrollerView.h"
#define kViewW self.frame.size.width
#define kViewH self.frame.size.height

@interface NSTimer (NSTimerBlocksSupport)

/**
 通过block解决NSTimer循环引用问题

 @param interval    时间间隔
 @param block       bock回调
 @param repeats     是否重复
 @return            NSTimer
 */
+ (NSTimer *)timer_scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                            block:(void(^)())block
                                          repeats:(BOOL)repeats;
@end

@implementation NSTimer (NSTimerBlocksSupport)
+ (NSTimer *)timer_scheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                            block:(void(^)())block
                                          repeats:(BOOL)repeats {
    return [self scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(timer_blockInvoke:)
                                       userInfo:[block copy]
                                        repeats:repeats];
}

+ (void)timer_blockInvoke:(NSTimer *)timer {
    void (^block)() = timer.userInfo;
    if(block) {
        block();
    }
}

@end


@interface ZOEScrollerView ()<UIScrollViewDelegate>
{
    NSInteger _currentPageIndex;//当前页数索引
    NSInteger _number;//图片总个数
}
@property (nonatomic,strong) UIScrollView   *scrollView;
@property (nonatomic,strong) UILabel        *noteTitle;
@property (nonatomic,strong) UIView         *noteView;
@property (nonatomic,strong) UIPageControl  *pageControl;
@property (nonatomic,assign) NSTimer        *timerTemp;

@end
@implementation ZOEScrollerView
@synthesize timeInterva = _timeInterva;

#pragma mark - 核心代码
- (void)configControl {
    if ([self.delegate respondsToSelector:@selector(numberOfPageSize)]) {
        _number = [self.delegate numberOfPageSize];
    }
    if (_number<=0)return;
    if (_scrollView) {
        for (UIView *view in [_scrollView subviews]) {
            [view removeFromSuperview];
        }
    }
    for (int pageIndex=0;pageIndex<_number;pageIndex++) {
        UIImageView *imgView=[[UIImageView alloc] init];
        imgView.contentMode=UIViewContentModeScaleToFill;
        imgView.clipsToBounds=YES;
        imgView.backgroundColor=[UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        if ([self.delegate respondsToSelector:@selector(scrollerView:imageView:configImageForPageInIndex:)]) {
            [self.delegate scrollerView:self imageView:imgView configImageForPageInIndex:pageIndex];
            if (pageIndex == 0 && _number!=1) {
                //尾元素
                UIImageView *imgViewLast=[[UIImageView alloc] init];
                imgViewLast.contentMode=UIViewContentModeScaleToFill;
                imgViewLast.clipsToBounds=YES;
                imgViewLast.backgroundColor=[UIColor colorWithRed:1 green:1 blue:1 alpha:1];
                [imgViewLast setFrame:CGRectMake((_number+1)*kViewW,
                                                 0,
                                                 kViewW,
                                                 kViewH)];
                imgViewLast.tag = 0;
                imgViewLast.image = imgView.image;
                UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
                [Tap setNumberOfTapsRequired:1];
                [Tap setNumberOfTouchesRequired:1];
                imgViewLast.userInteractionEnabled=YES;
                [imgViewLast addGestureRecognizer:Tap];
                [self.scrollView addSubview:imgViewLast];
            }else if (pageIndex == (_number-1) && _number!=1) {
                //首元素
                UIImageView *imgViewFirst=[[UIImageView alloc] init];
                imgViewFirst.contentMode=UIViewContentModeScaleToFill;
                imgViewFirst.clipsToBounds=YES;
                imgViewFirst.backgroundColor=[UIColor colorWithRed:1 green:1 blue:1 alpha:1];
                [imgViewFirst setFrame:CGRectMake(0,0,kViewW,kViewH)];
                imgViewFirst.tag = _number-1;
                imgViewFirst.image = imgView.image;
                UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
                [Tap setNumberOfTapsRequired:1];
                [Tap setNumberOfTouchesRequired:1];
                imgViewFirst.userInteractionEnabled=YES;
                [imgViewFirst addGestureRecognizer:Tap];
                [self.scrollView addSubview:imgViewFirst];
            }
        }
        CGFloat offsetX;
        if (_number == 1) {
            offsetX = pageIndex*kViewW;
        }else {
            offsetX = (pageIndex+1)*kViewW;
        }
        [imgView setFrame:CGRectMake(offsetX, 0,kViewW,kViewH)];
        imgView.tag = pageIndex;
        UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
        [Tap setNumberOfTapsRequired:1];
        [Tap setNumberOfTouchesRequired:1];
        imgView.userInteractionEnabled=YES;
        [imgView addGestureRecognizer:Tap];
        [self.scrollView addSubview:imgView];
    }
    [self.scrollView setContentOffset:CGPointMake(kViewW, 0)];
    [self addSubview:self.scrollView];
    //添加说明文字视图
    [self addSubview:self.noteView];
    // 添加定时器
    [self timerTemp];
    if (_number <=1) {
        [self.timerTemp invalidate];
        [self.pageControl removeFromSuperview];
        _scrollView.contentSize = CGSizeMake(kViewW,kViewH);
    }else {
        self.scrollView.contentSize = CGSizeMake(kViewW*(_number+2),kViewH);
    }
}

#pragma mark -scrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger pageIndex = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth);
    if (pageIndex>=_number)pageIndex=0;
    if (pageIndex<0)pageIndex=_number-1;
    if (pageIndex != _currentPageIndex) {
        _currentPageIndex = pageIndex;
        self.pageControl.currentPage = _currentPageIndex;
        if ([self.delegate respondsToSelector:@selector(scrollerView:noteTitle:configTitleForPageInIndex:)]) {
            [self.delegate scrollerView:self noteTitle:self.noteTitle configTitleForPageInIndex:_currentPageIndex];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView {
    [self.scrollView setContentOffset:CGPointMake((_currentPageIndex+1)*kViewW, 0)];
}

#pragma mark - Action
// 定时器 绑定的方法
- (void)runTimePage {
    if(_pageControl.currentPage == (_number-1)) {
        //到最后一页时，继续往后翻一页缓存页，然后无缝链接到第一页。（就是要欺骗你的眼睛）
        [UIView animateWithDuration:0.5 animations:^{
            [self.scrollView setContentOffset:CGPointMake((self.pageControl.currentPage+2)*kViewW, 0)];
        } completion:^(BOOL finished){
            self.pageControl.currentPage=0;
            [self.scrollView scrollRectToVisible:CGRectMake(kViewW,0,kViewW,150) animated:NO];
        }];
    }else {
        self.pageControl.currentPage++;
        [UIView animateWithDuration:0.5 animations:^{
            [self.scrollView setContentOffset:CGPointMake((self.pageControl.currentPage+1)*kViewW, 0)];
            [self.scrollView scrollRectToVisible:CGRectMake(kViewW*(self.pageControl.currentPage+1),0,kViewW,150) animated:NO];
        } completion:^(BOOL finished){
            
        }];
    }
    
}
//图片点击事件
- (void)imagePressed:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollerView:didSelectedInIndex:)]) {
        [self.delegate scrollerView:self didSelectedInIndex:sender.view.tag];
    }
//    [self.timerTemp setFireDate:[NSDate distantFuture]];//暂停
}

- (void)reloadData {
    [self configControl];
}


#pragma mark - Properties
//初始化scrollview
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView=[[UIScrollView alloc]initWithFrame:CGRectMake(0, 0,kViewW,kViewH)];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.scrollsToTop = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}
//初始化文本视图
- (UIView *)noteView {
    if (!_noteView) {
        _noteView=[[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-33,self.bounds.size.width,33)];
        [_noteView setBackgroundColor:[UIColor clearColor]];
    }
    [_noteView addSubview:self.pageControl];
    [_noteView addSubview:self.noteTitle];
    return _noteView;
}
//初始化翻页控件
- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0,10,[UIScreen mainScreen].bounds.size.width, 20.0f)];
        _pageControl.currentPage = 0;
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0/255.0 green:162/255.0 blue:255/255.0 alpha:1];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
        //_pageControl.pageIndicatorTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blue_circle_icon"]];
        [_pageControl setUserInteractionEnabled:NO];
        _pageControl.numberOfPages = _number;
    }
    return _pageControl;
}
//初始化文本title
- (UILabel *)noteTitle {
    if (!_noteTitle) {
        float pageControlWidth=(_number)*10.0f+40.f;
        _noteTitle=[[UILabel alloc] initWithFrame:CGRectMake(5, 6, self.frame.size.width-pageControlWidth-15, 20)];
        [_noteTitle setBackgroundColor:[UIColor clearColor]];
        _noteTitle.textColor=[UIColor whiteColor];
        [_noteTitle setFont:[UIFont systemFontOfSize:13]];
        if ([self.delegate respondsToSelector:@selector(scrollerView:noteTitle:configTitleForPageInIndex:)]) {
            [self.delegate scrollerView:self noteTitle:_noteTitle configTitleForPageInIndex:0];
        }
    }
    return _noteTitle;
}
//timer
- (NSTimer *)timer {
    return self.timerTemp;
}
- (NSTimer *)timerTemp {
    if (!_timerTemp) {
        __weak typeof(self)weakSelf = self;
        _timerTemp = [NSTimer timer_scheduledTimerWithTimeInterval:self.timeInterva
                                                     block:^{
                                                         __strong typeof(weakSelf)strongSelf = weakSelf;
                                                         [strongSelf runTimePage];
                                                     }
                                                   repeats:YES];
    }
    return _timerTemp;
}

- (void)setTimeInterva:(NSTimeInterval)timeInterva {
    _timeInterva = timeInterva;
    if (_timerTemp) {
        [_timerTemp invalidate];
        _timerTemp = nil;
        [self timerTemp];
    }
}

- (NSTimeInterval)timeInterva {
    if (_timeInterva<=0)return 3.0;
    return _timeInterva;
}

- (void)setDelegate:(id<ZOEScrollerViewDelegate>)delegate {
    _delegate = delegate;
    [self configControl];
}

@end


