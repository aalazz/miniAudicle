//
//  mAScriptPlayer.h
//  miniAudicle
//
//  Created by Spencer Salazar on 3/26/14.
//
//

#import <UIKit/UIKit.h>

@class mADetailItem;
class Chuck_VM_Status;

@interface mAScriptPlayer : UIViewController
{
    IBOutlet UILabel *titleLabel;
}

@property (strong, nonatomic) mADetailItem *detailItem;

- (IBAction)addShred:(id)sender;
- (IBAction)replaceShred:(id)sender;
- (IBAction)removeShred:(id)sender;

- (void)updateWithStatus:(Chuck_VM_Status *)status;

@end
