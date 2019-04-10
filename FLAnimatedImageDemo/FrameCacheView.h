//
//  FrameCacheView.h
//  UFLAnimatedImageDemo
//
//  Created by Raphael Schaad on 4/1/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//


#import <UIKit/UIKit.h>

@class UFLAnimatedImage;


@interface FrameCacheView : UIView

@property (nonatomic, strong) UFLAnimatedImage *image;
@property (nonatomic, strong) NSIndexSet *framesInCache;
@property (nonatomic, assign) NSUInteger requestedFrameIndex;

@end
