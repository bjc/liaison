//
//  NIBConnector.m
//  Liaison
//
//  Created by Brian Cully on Mon Mar 03 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "NIBConnector.h"

#import "CopyController.h"
#import "PreferencesController.h"

@implementation NIBConnector
static NIBConnector *sharedInstance = nil;
+ (NIBConnector *)connector
{
    // Set in awakeFromNib
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    
    thePreferencesController = nil;
    theCopyController = nil;

    return self;
}

- (void)awakeFromNib
{
    if (sharedInstance == nil)
        sharedInstance = self;
}

- (void)showPreferencesWindow: (id)sender
{
    if (thePreferencesController == nil)
        [NSBundle loadNibNamed: @"PreferencesWindow.nib" owner: self];
    [thePreferencesController showWindow];
}

- (IBAction)showDownloadWindow: (id)sender
{
    [[self copyController] showWindow];
}

- (CopyController *)copyController
{
    if (theCopyController == nil)
        [NSBundle loadNibNamed: @"CopyPanel.nib" owner: self];
    return theCopyController;
}

- (LoadPanelController *)loadPanelController
{
    if (theLoadPanelController == nil)
        [NSBundle loadNibNamed: @"LoadPanel.nib" owner: self];
    return theLoadPanelController;
}
@synthesize theCopyController;
@synthesize thePreferencesController;
@synthesize theLoadPanelController;
@end
