/*----------------------------------------------------------------------------
 miniAudicle iOS
 iOS GUI to chuck audio programming environment
 
 Copyright (c) 2005-2012 Spencer Salazar.  All rights reserved.
 http://chuck.cs.princeton.edu/
 http://soundlab.cs.princeton.edu/
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 U.S.A.
 -----------------------------------------------------------------------------*/

#import "mASocialFileViewController.h"

#import "mADetailViewController.h"
#import "mAEditorViewController.h"
#import "mAPlayerViewController.h"
#import "mAChucKController.h"
#import "miniAudicle.h"
#import "mADetailItem.h"
#import "mADocumentManager.h"
#import "mAAnalytics.h"
#import "mAAudioFileTableViewCell.h"
#import "mAFolderTableViewCell.h"
#import "mADirectoryViewController.h"
#import "UIAlert.h"
#import "mATableViewCell.h"


static NSString *CellIdentifier = @"Cell";

@interface mASocialFileViewController ()
{
    IBOutlet UIView *_loadingView;
    IBOutlet UILabel *_loadingStatusLabel;
}

@property (strong, nonatomic) IBOutlet UITableView * tableView;

@property (copy, nonatomic) NSString *loadingStatus;
@property (nonatomic) BOOL showsLoading;

@end


@implementation mASocialFileViewController

- (void)setLoadingStatus:(NSString *)loadingStatus
{
    _loadingStatus = loadingStatus;
    
    if(_loadingStatus)
        _loadingStatusLabel.text = _loadingStatus;
}

- (void)setShowsLoading:(BOOL)showsLoading
{
    _showsLoading = showsLoading;
    
    if(showsLoading)
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _loadingView.alpha = 1.0;
                         }];
    }
    else
    {
        [UIView animateWithDuration:0.25
                         animations:^{
                             _loadingView.alpha = 0.0;
                         }];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            self.preferredContentSize = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.loadingStatus = @"Loading Chuckpad Social";
    self.showsLoading = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (UINavigationItem *)navigationItem
{
    UINavigationItem *navigationItem = super.navigationItem;
    
    return navigationItem;
}

#pragma mark - IBActions


#pragma mark - UITableViewDelegate

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row;
    
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
