//
//  UFLAnimatedLayer.m
//  Branch-SDK
//
//  Created by Nicolas Coderre on 10/31/18.
//

#import <Foundation/Foundation.h>
#import "UFLAnimatedLayer.h"
#import "UFLAnimatedImage.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/kdebug_signpost.h>


@interface UFLAnimatedLayer ()

// Override of public `readonly` properties as private `readwrite`
@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;

@property (nonatomic, assign) NSUInteger loopCountdown;
@property (nonatomic, assign) NSTimeInterval accumulator;
@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;

@end


@implementation UFLAnimatedLayer
@synthesize runLoopMode = _runLoopMode;

#pragma mark - Initializers

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithAnimatedImage: (UFLAnimatedImage*)animatedImage {
  self = [super init];
  if (self) {
    [self commonInit];
    self.animatedImage = animatedImage;
  }
  return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.runLoopMode = [[self class] defaultRunLoopMode];
    
    self.bounds = CGRectMake( 0, 0, 100, 100); // initialize with something.
    self.anchorPoint = CGPointMake(0.0, 1.0);
    self.backgroundColor = [UIColor clearColor].CGColor;
}


#pragma mark - Accessors
#pragma mark Public

- (void)setAnimatedImage:(UFLAnimatedImage *)animatedImage
{
    if (![_animatedImage isEqual:animatedImage]) {
        if (animatedImage) {
            // Clear out the image.
            super.contents = nil;
        } else {
            // Stop animating before the animated image gets cleared out.
            [self stopAnimating];
        }
        
        _animatedImage = animatedImage;
        
        self.currentFrame = animatedImage.posterImage;
        self.contents =  (__bridge id)self.currentFrame.CGImage;
        CGSize size = animatedImage.posterImage.size;
        self.bounds = CGRectMake(0,0, size.width, size.height);
        
        self.currentFrameIndex = 0;
        if (animatedImage.loopCount > 0) {
            self.loopCountdown = animatedImage.loopCount;
        } else {
            self.loopCountdown = NSUIntegerMax;
        }
        self.accumulator = 0.0;
        
        // Start animating after the new animated image has been set.
        [self startAnimating];
        
        // needed?
        //[self setNeedsDisplay];
    }
}


#pragma mark - Life Cycle

- (void)dealloc
{
    // Removes the display link from all run loop modes.
    [_displayLink invalidate];
}


#pragma mark Animating Images

- (NSTimeInterval)frameDelayGreatestCommonDivisor
{
    // Presision is set to half of the `kUFLAnimatedImageDelayTimeIntervalMinimum` in order to minimize frame dropping.
    const NSTimeInterval kGreatestCommonDivisorPrecision = 2.0 / kUFLAnimatedImageDelayTimeIntervalMinimum;
    
    NSArray *delays = self.animatedImage.delayTimesForIndexes.allValues;
    
    // Scales the frame delays by `kGreatestCommonDivisorPrecision`
    // then converts it to an UInteger for in order to calculate the GCD.
    NSUInteger scaledGCD = lrint([delays.firstObject floatValue] * kGreatestCommonDivisorPrecision);
    for (NSNumber *value in delays) {
        scaledGCD = gcd(lrint([value floatValue] * kGreatestCommonDivisorPrecision), scaledGCD);
    }
    
    // Reverse to scale to get the value back into seconds.
    return scaledGCD / kGreatestCommonDivisorPrecision;
}


static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    if (a < b) {
        return gcd(b, a);
    } else if (a == b) {
        return b;
    }
    
    while (true) {
        NSUInteger remainder = a % b;
        if (remainder == 0) {
            return b;
        }
        a = b;
        b = remainder;
    }
}


- (void)startAnimating
{
    if (self.animatedImage) {
        // Lazily create the display link.
        if (!self.displayLink) {
            // It is important to note the use of a weak proxy here to avoid a retain cycle. `-displayLinkWithTarget:selector:`
            // will retain its target until it is invalidated. We use a weak proxy so that the image view will get deallocated
            // independent of the display link's lifetime. Upon image view deallocation, we invalidate the display
            // link which will lead to the deallocation of both the display link and the weak proxy.
            UFLWeakProxy *weakProxy = [UFLWeakProxy weakProxyForObject:self];
            self.displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayDidRefresh:)];
            
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        }
        
        // Note: The display link's `.frameInterval` value of 1 (default) means getting callbacks at the refresh rate of the display (~60Hz).
        // Setting it to 2 divides the frame rate by 2 and hence calls back at every other display refresh.
        const NSTimeInterval kDisplayRefreshRate = 60.0; // 60Hz
        self.displayLink.frameInterval = MAX([self frameDelayGreatestCommonDivisor] * kDisplayRefreshRate, 1);
        
        self.displayLink.paused = NO;
    }
}

- (void)setRunLoopMode:(NSString *)runLoopMode
{
    if (![@[NSDefaultRunLoopMode, NSRunLoopCommonModes] containsObject:runLoopMode]) {
        NSAssert(NO, @"Invalid run loop mode: %@", runLoopMode);
        _runLoopMode = [[self class] defaultRunLoopMode];
    } else {
        _runLoopMode = runLoopMode;
    }
}

- (void)stopAnimating
{
    if (self.animatedImage) {
        self.displayLink.paused = YES;
    }
}


- (BOOL)isAnimating
{
    BOOL isAnimating = NO;
    if (self.animatedImage) {
        isAnimating = self.displayLink && !self.displayLink.isPaused;
    } else {
        isAnimating = false; //[super isAnimating];
    }
    return isAnimating;
}


#pragma mark - Private Methods
#pragma mark Animation

- (void)displayDidRefresh:(CADisplayLink *)displayLink
{
    kdebug_signpost_start(71, 0, 0, 0, 0);
    /*  for (UFLAnimatedImageView* obj in _liveViews) {
     [obj displayDidRefresh:nil];
     }*/

    NSNumber *delayTimeNumber = [self.animatedImage.delayTimesForIndexes objectForKey:@(self.currentFrameIndex)];
    // If we don't have a frame delay (e.g. corrupt frame), don't update the view but skip the playhead to the next frame (in else-block).
    if (delayTimeNumber) {
        NSTimeInterval delayTime = [delayTimeNumber floatValue];
        // If we have a nil image (e.g. waiting for frame), don't update the view nor playhead.
        UIImage *image = [self.animatedImage imageLazilyCachedAtIndex:self.currentFrameIndex];
        if (image) {
            UFLLog(UFLLogLevelVerbose, @"Showing frame %lu for animated image: %@", (unsigned long)self.currentFrameIndex, self.animatedImage);
            
            self.contents = (__bridge id)image.CGImage;
            
            self.currentFrame = image;
            
            if (self.needsDisplayWhenImageBecomesAvailable) {
//                [self setNeedsDisplay];
                self.needsDisplayWhenImageBecomesAvailable = NO;
            }
            
            self.accumulator += displayLink.duration * displayLink.frameInterval;
            
            // While-loop first inspired by & good Karma to: https://github.com/ondalabs/OLImageView/blob/master/OLImageView.m
            while (self.accumulator >= delayTime) {
                self.accumulator -= delayTime;
                self.currentFrameIndex++;
                if (self.currentFrameIndex >= self.animatedImage.frameCount) {
                    // If we've looped the number of times that this animated image describes, stop looping.
                    self.loopCountdown--;
                    if (self.loopCompletionBlock) {
                        self.loopCompletionBlock(self.loopCountdown);
                    }
                    
                    if (self.loopCountdown == 0) {
                        [self stopAnimating];
                        return;
                    }
                    self.currentFrameIndex = 0;
                }
                // Calling `-setNeedsDisplay` will just paint the current frame, not the new frame that we may have moved to.
                // Instead, set `needsDisplayWhenImageBecomesAvailable` to `YES` -- this will paint the new image once loaded.
                self.needsDisplayWhenImageBecomesAvailable = YES;
            }
        } else {
            UFLLog(UFLLogLevelDebug, @"Waiting for frame %lu for animated image: %@", (unsigned long)self.currentFrameIndex, self.animatedImage);
        }
    } else {
        self.currentFrameIndex++;
    }
    kdebug_signpost_end(71, 0, 0, 0, 0);
}

+ (NSString *)defaultRunLoopMode
{
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}

@end
