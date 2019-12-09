//
//  ZOEScrollerView.m
//  AiyoyouCocoapods
//
//  Created by aiyoyou on 16/1/5.
//  Copyright © 2016年 gulu. All rights reserved.
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
@property (nonatomic,assign) NSTimer        *timer;

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
        //父控件大小发生改变 scrollView及noteView大小也要跟着变
        if (!CGRectEqualToRect(_scrollView.bounds,self.bounds)) {
            _scrollView.frame = CGRectMake(0,0,kViewW,kViewH);
            if (_noteView) {
                _noteView.frame = CGRectMake(0,kViewH-33,kViewW,33);
            }
            if (_pageControl) {
                _pageControl.frame = CGRectMake(0,10,kViewW,20.0f);
            }
        }
        for (UIView *view in [_scrollView subviews]) {
            [view removeFromSuperview];
        }
    }
    for (int pageIndex=0;pageIndex<_number;pageIndex++) {
        UIImageView *imgView = [ZOEScrollerView createImageView];
        UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
        [Tap setNumberOfTapsRequired:1];
        [Tap setNumberOfTouchesRequired:1];
        [imgView addGestureRecognizer:Tap];
        if ([self.delegate respondsToSelector:@selector(scrollerView:imageView:configImageForPageInIndex:)]) {
            [self.delegate scrollerView:self imageView:imgView configImageForPageInIndex:pageIndex];
            if (pageIndex == 0 && _number!=1) {
                //尾元素
                UIImageView *imgViewLast = [ZOEScrollerView createImageView];
                UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
                [Tap setNumberOfTapsRequired:1];
                [Tap setNumberOfTouchesRequired:1];
                [imgViewLast addGestureRecognizer:Tap];
                [self.delegate scrollerView:self imageView:imgViewLast configImageForPageInIndex:pageIndex];
                if (self.rollingDirection == Rolling_Horizontal) {
                    [imgViewLast setFrame:CGRectMake((_number+1)*kViewW,0,kViewW,kViewH)];
                }else {
                    [imgViewLast setFrame:CGRectMake(0,(_number+1)*kViewH,kViewW,kViewH)];
                }
                
                imgViewLast.tag = 0;
                [self.scrollView addSubview:imgViewLast];
            }else if (pageIndex == (_number-1) && _number!=1) {
                //首元素
                UIImageView *imgViewFirst = [ZOEScrollerView createImageView];
                UITapGestureRecognizer *Tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePressed:)] ;
                [Tap setNumberOfTapsRequired:1];
                [Tap setNumberOfTouchesRequired:1];
                [imgViewFirst addGestureRecognizer:Tap];
                [self.delegate scrollerView:self imageView:imgViewFirst configImageForPageInIndex:pageIndex];
                [imgViewFirst setFrame:CGRectMake(0,0,kViewW,kViewH)];
                imgViewFirst.tag = _number-1;
                [self.scrollView addSubview:imgViewFirst];
            }
        }
        CGFloat offsetX;
        if (_number == 1) {
            if (self.rollingDirection == Rolling_Horizontal) {
                offsetX = pageIndex*kViewW;
            }else {
                offsetX = pageIndex*kViewH;
            }
            
        }else {
            if (self.rollingDirection == Rolling_Horizontal) {
                offsetX = (pageIndex+1)*kViewW;
            }else {
                offsetX = (pageIndex+1)*kViewH;
            }
            
        }
        if (self.rollingDirection == Rolling_Horizontal) {
            [imgView setFrame:CGRectMake(offsetX, 0,kViewW,kViewH)];
        }else {
            [imgView setFrame:CGRectMake(0,offsetX,kViewW,kViewH)];
        }
        
        imgView.tag = pageIndex;
        [self.scrollView addSubview:imgView];
    }
    [self addSubview:self.scrollView];
    //添加说明文字视图
    if (self.rollingDirection == Rolling_Horizontal) {
        [self addSubview:self.noteView];
    }
    // 添加定时器
    [self timer];
    if (_number <=1) {
        [_timer invalidate];
        _timer = nil;
        [_pageControl removeFromSuperview];
        [self.scrollView setContentOffset:CGPointMake(0, 0)];
        _scrollView.contentSize = CGSizeMake(kViewW,kViewH);
    }else {
        self.pageControl.currentPage = 0;
        self.pageControl.numberOfPages = _number;
        if (self.rollingDirection == Rolling_Horizontal) {
            [self.scrollView setContentOffset:CGPointMake(kViewW, 0)];
            self.scrollView.contentSize = CGSizeMake(kViewW*(_number+2),kViewH);
        }else {
            [self.scrollView setContentOffset:CGPointMake(0,kViewH)];
            self.scrollView.contentSize = CGSizeMake(kViewW,kViewH*(_number+2));
        }
        
    }
}

+ (UIImageView *)createImageView {
    UIImageView *imageView=[[UIImageView alloc] init];
    imageView.contentMode=UIViewContentModeScaleToFill;
    imageView.clipsToBounds=YES;
    imageView.userInteractionEnabled=YES;
    return imageView;
}

#pragma mark -scrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if (self.rollingDirection == Rolling_Horizontal) {
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
    }else {
        CGFloat pageHeight = self.scrollView.frame.size.height;
        NSInteger pageIndex = floor((self.scrollView.contentOffset.y - pageHeight / 2) / pageHeight);
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
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView {
    if (self.rollingDirection == Rolling_Horizontal) {
        [self.scrollView setContentOffset:CGPointMake((_currentPageIndex+1)*kViewW, 0)];
    }else {
        [self.scrollView setContentOffset:CGPointMake(0,(_currentPageIndex+1)*kViewH)];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self timer];
}

#pragma mark - Action
// 定时器 绑定的方法
- (void)runTimePage {
    if(_pageControl.currentPage == (_number-1)) {
        //到最后一页时，继续往后翻一页缓存页，然后无缝链接到第一页。
        [UIView animateWithDuration:0.5 animations:^{
            if (self.rollingDirection == Rolling_Horizontal) {
                [self.scrollView setContentOffset:CGPointMake((self.pageControl.currentPage+2)*kViewW, 0)];
            }else {
                [self.scrollView setContentOffset:CGPointMake(0, (self.pageControl.currentPage+2)*kViewH)];
            }
            
        } completion:^(BOOL finished){
            if (self.rollingDirection == Rolling_Horizontal) {
                self.pageControl.currentPage=0;
                [self.scrollView scrollRectToVisible:CGRectMake(kViewW,0,kViewW,kViewH) animated:NO];
            }else {
                self.pageControl.currentPage=0;
                [self.scrollView scrollRectToVisible:CGRectMake(0,kViewH,kViewW,kViewH) animated:NO];
            }
            
        }];
    }else {
        self.pageControl.currentPage++;
        [UIView animateWithDuration:0.5 animations:^{
            if (self.rollingDirection == Rolling_Horizontal) {
                [self.scrollView setContentOffset:CGPointMake((self.pageControl.currentPage+1)*kViewW, 0)];
                [self.scrollView scrollRectToVisible:CGRectMake(kViewW*(self.pageControl.currentPage+1),0,kViewW,kViewH) animated:NO];
            }else {
                [self.scrollView setContentOffset:CGPointMake(0, (self.pageControl.currentPage+1)*kViewH)];
                [self.scrollView scrollRectToVisible:CGRectMake(0,kViewH*(self.pageControl.currentPage+1),kViewW,kViewH) animated:NO];
            }
            
        } completion:^(BOOL finished){
            
        }];
    }
    
}
//图片点击事件
- (void)imagePressed:(UITapGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollerView:didSelectedInIndex:)]) {
        [self.delegate scrollerView:self didSelectedInIndex:sender.view.tag];
    }
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
        _pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0,10,self.bounds.size.width, 20.0f)];
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0/255.0 green:162/255.0 blue:255/255.0 alpha:1];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1];
        //_pageControl.pageIndicatorTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blue_circle_icon"]];
        [_pageControl setUserInteractionEnabled:NO];
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
    if (!_timer) {
        __weak typeof(self)weakSelf = self;
        _timer = [NSTimer timer_scheduledTimerWithTimeInterval:self.timeInterva
                                                         block:^{
                                                             __strong typeof(weakSelf)strongSelf = weakSelf;
                                                             [strongSelf runTimePage];
                                                         }
                                                       repeats:YES];
        //UITrackingRunLoopMode模式的作用是当用户拖动tableView、collectionView等事件时定时器仍然会处理事件
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];
    }
    return _timer;
}

- (void)setTimeInterva:(NSTimeInterval)timeInterva {
    _timeInterva = timeInterva;
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
        [self timer];
    }
}

- (NSTimeInterval)timeInterva {
    if (_timeInterva<=0)return 3.0;
    return _timeInterva;
}

//- (void)setDelegate:(id<ZOEScrollerViewDelegate>)delegate {
//    _delegate = delegate;
//    [self configControl];
//}

@end


