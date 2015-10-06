//
//  VIMUploadSessionManager.h
//  Pods
//
//  Created by Hanssen, Alfie on 9/8/15.
//
//

#import "VIMNetworkTaskSessionManager.h"

@interface VIMUploadSessionManager : VIMNetworkTaskSessionManager

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration;

@end
