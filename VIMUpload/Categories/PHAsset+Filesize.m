//
//  PHAsset+Filesize.m
//  VIMNetworking
//
//  Created by Hanssen, Alfie on 5/14/15.
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

#import "PHAsset+Filesize.h"
#import "AVAsset+Filesize.h"

@implementation PHAsset (Filesize)

- (CGFloat)calculateFilesize
{
    __block CGFloat size = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    
    [self calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {
       
        size = fileSize;
        
        dispatch_group_leave(group);
        
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return size;
}

- (int32_t)calculateFilesizeWithCompletionBlock:(FileSizeCompletionBlock)completionBlock
{
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat; // TODO: How does this impact things? [AH]
    options.networkAccessAllowed = YES; // TODO: is this a problem? [AH]

    return [[PHImageManager defaultManager] requestAVAssetForVideo:self options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        
        [asset calculateFilesizeWithCompletionBlock:^(CGFloat fileSize, NSError *error) {
            
            if (completionBlock)
            {
                NSError *error = info[PHImageErrorKey];
                completionBlock(fileSize, error);
            }

        }];
        
    }];
}

@end
