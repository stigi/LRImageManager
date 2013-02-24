// LRImagePresenter.m
//
// Copyright (c) 2013 Luis Recuenco
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LRImagePresenter.h"
#import "LRImageManager.h"

@interface LRImagePresenter ()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) LRCacheStorageOptions storageOptions;
@property (nonatomic, assign) LRImageViewAnimationOptions animationOptions;

@end

@implementation LRImagePresenter

+ (instancetype)presenterForImageView:(UIImageView *)imageView
                              withURL:(NSURL *)url
                     placeholderImage:(UIImage *)placeholderImage
                                 size:(CGSize)size
                       storageOptions:(LRCacheStorageOptions)storageOptions
                     animationOptions:(LRImageViewAnimationOptions)animationOptions
{
    return [[self alloc] initWithImageView:imageView
                                   withURL:url
                          placeholderImage:placeholderImage
                                      size:size
                            storageOptions:storageOptions
                          animationOptions:animationOptions];
}

- (id)initWithImageView:(UIImageView *)imageView
                withURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                   size:(CGSize)size
         storageOptions:(LRCacheStorageOptions)storageOptions
       animationOptions:(LRImageViewAnimationOptions)animationOptions
{
    self = [super init];
    
    if (self)
    {
        _imageView = imageView;
        _imageURL = url;
        _imageSize = size;
        _placeholderImage = placeholderImage;
        _storageOptions = storageOptions;
        _animationOptions = animationOptions;
    }
    
    return self;
}

- (void)startPresenting
{
    if ([self.imageURL.absoluteString length] == 0)
    {
        self.imageView.image = self.placeholderImage;
        return;
    }
    
    UIImage *memCachedImage = [[LRImageCache sharedImageCache] memCachedImageForURL:self.imageURL
                                                                               size:self.imageSize];
    if (memCachedImage)
    {
        self.imageView.image = memCachedImage;
    }
    else
    {
        self.imageView.image = self.placeholderImage;
        
        __weak LRImagePresenter *wself = self;
        
        LRImageCompletionHandler completionHandler = ^(UIImage *image, NSError *error) {
            
            __strong LRImagePresenter *sself = wself;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (!image || error) return;
                
                if (self.animationOptions == LRImageViewAnimationOptionFade)
                {
                    [UIView transitionWithView:sself.imageView
                                      duration:0.25
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        sself.imageView.image = image;
                                    } completion:NULL];
                }
                else
                {
                    sself.imageView.image = image;
                }
            });
        };
        
        [[LRImageManager sharedManager] imageFromURL:self.imageURL
                                                size:self.imageSize
                                      storageOptions:self.storageOptions
                                   completionHandler:completionHandler];
    }
    
}

- (void)cancelPresenting
{
    [[LRImageManager sharedManager] cancelImageRequestFromURL:self.imageURL
                                                         size:self.imageSize];
}

@end