//
//  VIMUploadSessionManager.m
//  Pods
//
//  Created by Hanssen, Alfie on 9/8/15.
//
//

#import "VIMUploadSessionManager.h"

static NSString *const VimeoBaseURLString = @"https://api.vimeo.com/";

@implementation VIMUploadSessionManager

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSURL *url = [NSURL URLWithString:VimeoBaseURLString];
    
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self)
    {
        
    }

    return self;
}

@end
