/*
 * HCDownloadCell.h
 * HCDownload
 *
 * Created by Árpád Goretity on 25/07/2012.
 * Licensed under the 3-clause BSD License
 */

#import <UIKit/UIKit.h>

#define kHCDownloadCellID @"HCDLCell"
#define kHCDownloadCellHeight (44.0f)

@interface HCDownloadCell: UITableViewCell {
	UIProgressView *progressView;
}

@property (nonatomic, assign) float progress;

+ (id)cell;

@end
