//
//  FLAnimatedCALayer.h
//  Pods
//
//  Created by Nicolas Coderre on 10/31/18.
//

#ifndef FLAnimatedLayer_h
#define FLAnimatedLayer_h

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@class FLAnimatedImage;
@protocol FLAnimatedImageViewDebugDelegate;

//
//  An `FLAnimatedImageView` can take an `FLAnimatedImage` and plays it automatically when in view hierarchy and stops when removed.
//  The animation can also be controlled with the `UIImageView` methods `-start/stop/isAnimating`.
//  It is a fully compatible `UIImageView` subclass and can be used as a drop-in component to work with existing code paths expecting to display a `UIImage`.
//  Under the hood it uses a `CADisplayLink` for playback, which can be inspected with `currentFrame` & `currentFrameIndex`.
//
@interface FLAnimatedLayer : CALayer

@property (nonatomic, strong) FLAnimatedImage *animatedImage;
@property (nonatomic, copy) void(^loopCompletionBlock)(NSUInteger loopCountRemaining);

@property (nonatomic, strong, readonly) UIImage *currentFrame;
@property (nonatomic, assign, readonly) NSUInteger currentFrameIndex;

// The animation runloop mode. Enables playback during scrolling by allowing timer events (i.e. animation) with NSRunLoopCommonModes.
// To keep scrolling smooth on single-core devices such as iPhone 3GS/4 and iPod Touch 4th gen, the default run loop mode is NSDefaultRunLoopMode. Otherwise, the default is NSDefaultRunLoopMode.
@property (nonatomic, copy) NSString *runLoopMode;

- (void)displayDidRefresh:(CADisplayLink *)displayLink;

@end




#endif /* FLAnimatedLayer_h */
