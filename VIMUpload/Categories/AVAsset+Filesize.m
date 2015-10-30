//
//  AVAsset+Filesize.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 4/16/15.
//  Copyright (c) 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "AVAsset+Filesize.h"
#import <AVFoundation/AVComposition.h>
#import <AVFoundation/AVCompositionTrack.h>
#import <AVFoundation/AVCompositionTrackSegment.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation AVAsset (Filesize)

- (uint64_t)calculateFileSizeInBytes
{
    __block uint64_t size = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);

    [self calculateFileSizeInBytesWithCompletionBlock:^(uint64_t fileSizeInBytes, NSError *error) {
        
        size = fileSizeInBytes;
       
        dispatch_group_leave(group);
        
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return size;
}

- (void)calculateFileSizeInBytesWithCompletionBlock:(FileSizeInBytesCompletionBlock)completionBlock
{
    uint64_t rawSize = 0;
    
    if ([self isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset *asset = (AVURLAsset *)self;
        
        if ([[asset.URL scheme] isEqualToString:@"assets-library"])
        {
            [[[ALAssetsLibrary alloc] init] assetForURL:asset.URL resultBlock:^(ALAsset *asset) {
                
                uint64_t sizeBytes = [[asset defaultRepresentation] size];
                
                if (completionBlock)
                {
                    completionBlock(sizeBytes, nil);
                }

            } failureBlock:^(NSError *error) {
                
                if (completionBlock)
                {
                    completionBlock(0, error);
                }
                
            }];
            
            return;
        }
        
        NSNumber *size = nil;
        NSError *error = nil;

        BOOL success = [asset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
        
        if (success)
        {
            rawSize = [size unsignedLongLongValue];
        }
    }
    
    if (rawSize == 0 || [self isKindOfClass:[AVComposition class]])
    {
        float estimatedSize = 0.0;
        
        NSArray *tracks = [self tracks];
        for (AVAssetTrack * track in tracks)
        {
            float rate = [track estimatedDataRate] / 8.0f; // convert bits per second to bytes per second
            float seconds = CMTimeGetSeconds([track timeRange].duration);
            estimatedSize += seconds * rate;
        }
        
        rawSize = estimatedSize;
    }
    
    if (completionBlock)
    {
        completionBlock(rawSize, nil);
    }
}

@end
