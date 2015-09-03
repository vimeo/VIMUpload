# VIMUpload

`VIMUpload` is an Objective-C library that enables upload of videos to Vimeo. Its core component is a serial task queue that executes composite tasks (tasks with subtasks). 

The upload system uses a background configured NSURLSession to manage a queue of video uploads (i.e. uploads continue regardless of whether the app is in the foreground or background). It can be configured to manage two background sessions if you plan on initiating uploads from within an app as well as an extension.

The upload queue can be paused and resumed, and it is automatically paused/resumed when losing/gaining an internet connection. It can also be configured to restrict uploads to wifi only. 

The queue is persisted to disk so that in the event of an app termination event it can be reconstructed to the state it was in before termination.

If you're looking to interact with the Vimeo API for things other than video upload, check out [VIMNetworking](https://github.com/vimeo/VIMNetworking).

## Sample Project

Check out the [Pegasus] (https://github.com/vimeo/Pegasus) sample project.

## Setup

### Cocoapods

```Ruby
# Add this to your podfile
target 'YourTarget' do
	pod 'VIMUpload', '1.0.0' # Replace with the latest version
end
```

Note that VIMUpload depends on `AFNetworking`. It will be imported as a pod. 

###Git Submodules

To be documented 

## Prerequisites

1. Ensure that you've verified your Vimeo account. When you create an account, you'll receive an email asking that you verify your account. Until you verify your account you will not be able to upload videos using the API. 
2. Ensure you have been granted permission to use the "upload" scope. This permission must explicitly be granted by Vimeo API admins. You can request this permission on your app page under "Request upload access". Visit [developer.vimeo.com](https://developer.vimeo.com/).

## Initialization

When you configure VIMNetworking, set the `backgroundSessionIdentifierApp` property and include the "upload" permission in your scope. If you plan to initiate uploads from an extension, set the `backgroundSessionIdentifierExtension` and `sharedContainerID` properties as well.

```Obejctive-C
VIMSessionConfiguration *config = [[VIMSessionConfiguration alloc] init];
config.clientKey = @"your_client_key";
config.clientSecret = @"your_client_secret";
config.scope = @"private public create edit delete interact upload";
config.backgroundSessionIdentifierApp = @"your_app_background_session_id";
config.backgroundSessionIdentifierExtension = @"your_extension_background_session_id";
config.sharedContainerID = @"your_shared_container_id";
```

Load the `VIMUploadTaskQueue`(s) at each launch.

```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // ...

    [VIMUploadTaskQueue sharedAppQueue];
    [VIMUploadTaskQueue sharedExtensionQueue];

    return YES;
}
```

Implement the `application:andleEventsForBackgroundURLSession:completionHandler:` method in your AppDelegate:

```Objective-C
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:BackgroundSessionIdentifierApp])
    {
        [VIMUploadSessionManager sharedAppInstance].completionHandler = completionHandler;
    }
    else if ([identifier isEqualToString:BackgroundSessionIdentifierExtension])
    {
        [VIMUploadSessionManager sharedExtensionInstance].completionHandler = completionHandler;
    }
}
```

## Uploading Videos 

Enqueue a `PHAsset` for upload.

```Objective-C
PHAsset *asset = ...;
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithPHAsset:asset];
[[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue an `AVURLAsset` for upload.

```Objective-C
NSURL *URL = ...;
AVURLAsset *URLAsset = [AVURLAsset assetWithURL:URL];
BOOL canUploadFromSource = ...; // If the asset doesn't need to be copied to a tmp directory before upload, set this to YES
VIMVideoAsset *videoAsset = [[VIMVideoAsset alloc] initWithURLAsset:URLAsset canUploadFromSource:canUploadFromSource];
[[VIMUploadTaskQueue sharedExtensionQueue] uploadVideoAssets:@[videoAsset]];
```

Enqueue multiple assets for upload.

```Objective-C
NSArray *videoAssets = @[...];
[[VIMUploadTaskQueue sharedAppQueue] uploadVideoAssets:videoAssets];
```

Cancel an upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;
[[VIMUploadTaskQueue sharedAppQueue] cancelUploadForVideoAsset:videoAsset];
```

Cancel all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] cancelAllUploads];
```

Pause all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] pause];
```

Resume all uploads.

```Objective-C
[[VIMUploadTaskQueue sharedAppQueue] resume];
```

Ensure that uploads only occur when connected via wifi...or not. If `cellularUploadEnabled` is set to `NO`, the upload queue will automatically pause when leaving wifi and automatically resume when entering wifi. (Note: the queue will automatically pause/resume when the device is taken offline/online.)

```Objective-C
[VIMUploadTaskQueue sharedAppQueue].cellularUploadEnabled = NO;
```

Add video metadata to an enqueued or in-progress upload.

```Objective-C
VIMVideoAsset *videoAsset = ...;

VIMVideoMetadata *videoMetadata = [[VIMVideoMetadata alloc] init];
videoMetadata.videoTitle = @"Really cool title";
videoMetadata.videoDescription = @"Really cool description"";
videoMetadata.videoPrivacy = (NSString *)VIMPrivacyValue_Private;

[[VIMUploadTaskQueue sharedAppQueue] addMetadata:videoMetadata toVideoAsset:videoAsset withCompletionBlock:^(BOOL didAdd) {
    
    if (!didAdd)
    {
        // The upload has already finished, 
        // Set the metadata using the VIMAPIClient method updateVideoWithURI:title:description:privacy:completionHandler:
    }
    
}];
```

## Tracking Upload State & Progress

If you build UI to support pause and resume, listen for the `VIMNetworkTaskQueue_DidSuspendOrResumeNotification` notification and update your UI accordingly.

```Objective-C
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadTaskQueueDidSuspendOrResume:) name:VIMNetworkTaskQueue_DidSuspendOrResumeNotification object:nil];
}

- (void)uploadTaskQueueDidSuspendOrResume:(NSNotification *)notification
{
    BOOL isSuspended = [[VIMUploadTaskQueue sharedAppQueue] isSuspended];
    [self.pauseResumeButton setSelected:isSuspended];
}
```

Use KVO to communicate upload state and upload progress via your UI. Observe changes to `VIMVideoAsset`'s `uploadState` and `uploadProgressFraction` properties.

```Objective-C
static void *UploadStateContext = &UploadStateContext;
static void *UploadProgressContext = &UploadProgressContext;

- (void)addObservers
{
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) options:NSKeyValueObservingOptionNew context:UploadStateContext];
    
    [self.videoAsset addObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) options:NSKeyValueObservingOptionNew context:UploadProgressContext];
}

- (void)removeObservers
{
    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadState)) context:UploadStateContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }

    @try
    {
        [self.videoAsset removeObserver:self forKeyPath:NSStringFromSelector(@selector(uploadProgressFraction)) context:UploadProgressContext];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception removing observer: %@", exception);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == UploadStateContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadState))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadStateDidChange];
            });
        }
    }
    else if (context == UploadProgressContext)
    {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadProgressFraction))])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadProgressDidChange];
            });
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

When your UI is loaded or refreshed, associate your newly create VIMVideoAsset objects with their upload task counterparts so your UI continues to communicate upload state and progress.

```Objective-C
NSArray *videoAssets = self.datasource.items; // For example
[[VIMUploadTaskQueue sharedAppQueue] associateVideoAssetsWithUploads:videoAssets];
```

## License

`VIMUpload` is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
