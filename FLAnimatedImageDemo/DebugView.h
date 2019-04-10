//
//  DebugView.h
//  UFLAnimatedImageDemo
//
//  Created by Raphael Schaad on 4/1/14.
//  Copyright (c) 2014 Flipboard. All rights reserved.
//


#import <UFLAnimatedImage/UFLAnimatedImage.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DebugViewStyle) {
    DebugViewStyleDefault,
    DebugViewStyleCondensed
};


// Conforms to private UFLAnimatedImageDebugDelegate and UFLAnimatedImageViewDebugDelegate protocols, used in sample project.
@interface DebugView : UIView

@property (nonatomic, weak) UFLAnimatedImage *image;
@property (nonatomic, weak) UFLAnimatedImageView *imageView;
@property (nonatomic, assign) DebugViewStyle style;

@end
