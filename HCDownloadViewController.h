/*
 * HCDownloadViewController.h
 * HCDownload
 *
 * Created by Árpád Goretity on 25/07/2012.
 * Licensed under the 3-clause BSD License
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HCDownloadCell.h"

#define kHCDownloadKeyTitle @"key"
#define kHCDownloadKeyImage @"image"
#define kHCDownloadKeyFileName @"fileName"
#define kHCDownloadErrorDomain @"HCDownloadErrorDomain"
#define kHCDownloadErrorCodeCancelled (-1)

@class HCDownloadViewController;

@protocol HCDownloadViewControllerDelegate <NSObject>
@optional
- (void)downloadController:(HCDownloadViewController *)vc startedDownloadingURL:(NSURL *)url userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc dowloadedFromURL:(NSURL *)url progress:(float)progress userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc finishedDownloadingURL:(NSURL *)url toFile:(NSString *)fileName userInfo:(NSDictionary *)userInfo;
- (void)downloadController:(HCDownloadViewController *)vc failedDownloadingURL:(NSURL *)url withError:(NSError *)error userInfo:(NSDictionary *)userInfo;
@end

@interface HCDownloadViewController: UITableViewController {
	NSMutableArray *downloads;
	NSString *downloadDirectory;
	id <HCDownloadViewControllerDelegate> delegate;
}

@property (nonatomic, copy) NSString *downloadDirectory;
@property (nonatomic, readonly) NSInteger numberOfDownloads;
@property (nonatomic, assign) id <HCDownloadViewControllerDelegate> delegate;

- (void)downloadURL:(NSURL *)url userInfo:(NSDictionary *)userInfo;

@end
