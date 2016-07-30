@import Photos;

#import <UIKit/UIKit.h>
#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTUIManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "RNALAssetsLibrary.h"



@implementation RNALAssetsLibrary

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}


RCT_EXPORT_METHOD(
                  saveImageToAlbum:(nonnull NSNumber *)reactTag
                  albumName:(NSString *)album
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
  UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
  
  // defaults: snapshot the same size as the view, with alpha transparency, with current device's scale factor
  UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
  
  [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height) afterScreenUpdates:YES];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  NSNumber *width  = [NSNumber numberWithFloat:image.size.width];
  NSNumber *height = [NSNumber numberWithFloat:image.size.height];
  
  ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
  [library saveImage:image toAlbum:album completion:^(NSURL *assetURL, NSError *error) {
      NSDictionary * image = @{
                             @"uri":[assetURL absoluteString],
                             @"width":width,
                             @"height":height
                             };
      resolve(image);
  } failure:^(NSError *error) {
      reject(@"500", @"Problem saving image to album", error);
  }];
}

RCT_EXPORT_METHOD(
                  getSavedImages:(nonnull NSString *)album
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject
                  )
{
  if([ALAssetsLibrary authorizationStatus])
  {
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    [library getImagesFromAlbum:album completion:^(NSMutableArray *images, NSError *error) {
      if(error) {
        return reject(@"500", @"Problem getting images from album.", error);
      }
      resolve([images copy]);
    }];
  }
  else{
    reject(@"403", @"Permission denied `getSavedImages`", [NSError errorWithDomain:@"Permission denied" code:403 userInfo:NULL]);
  }
}



@end
