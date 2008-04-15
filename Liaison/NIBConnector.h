//
//  NIBConnector.h
//  Liaison
//
//  Created by Brian Cully on Mon Mar 03 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@class PreferencesController;
@class CopyController;
@class LoadPanelController;

// Links to other NIB controllers.
@interface NIBConnector : NSObject {
    IBOutlet PreferencesController *thePreferencesController;
    IBOutlet CopyController *theCopyController;
    IBOutlet LoadPanelController *theLoadPanelController;
}

+ (NIBConnector *)connector;

- (IBAction)showPreferencesWindow: (id)sender;
- (IBAction)showDownloadWindow: (id)sender;

- (CopyController *)copyController;
- (LoadPanelController *)loadPanelController;
@property (retain) CopyController *theCopyController;
@property (retain) LoadPanelController *theLoadPanelController;
@property (retain) PreferencesController *thePreferencesController;
@end
