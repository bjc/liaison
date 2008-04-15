//
//  InspectorViewController.h
//  Liaison
//
//  Created by Brian Cully on Wed May 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiFileHandle (LiLocationStuff)
- (NSString *)location;
@end

@interface InspectorViewController : NSObject
{
    IBOutlet NSView *theFileTabView;
    IBOutlet NSView *theHFSTabView;
    
    IBOutlet NSTextField *theFilenameField;
    IBOutlet NSTextField *theTypeField;
    IBOutlet NSPopUpButton *theApplicationButton;
    
    IBOutlet NSImageView *iconView;
    IBOutlet NSTextField *pathField;
    IBOutlet NSTextField *hfsTypeField;
    IBOutlet NSTextField *hfsCreatorField;

    LiFileHandle *theFile;
}
- (IBAction)setIcon:(id)sender;
- (IBAction)setFilename:(id)sender;
- (IBAction)setType:(id)sender;
- (IBAction)setApplication:(id)sender;
- (IBAction)setHFSTypeField:(id)sender;
- (IBAction)setHFSCreatorField:(id)sender;
@property (retain) NSPopUpButton *theApplicationButton;
@property (retain) NSImageView *iconView;
@property (retain) NSTextField *hfsCreatorField;
@property (retain,getter=hfsView) NSView *theHFSTabView;
@property (retain) NSTextField *theTypeField;
@property (retain,getter=fileView) NSView *theFileTabView;
@property (retain,getter=file) LiFileHandle *theFile;
@property (retain) NSTextField *pathField;
@property (retain) NSTextField *theFilenameField;
@property (retain) NSTextField *hfsTypeField;
@end

@interface InspectorViewController (Accessors)
- (NSView *)fileView;
- (NSView *)hfsView;
- (LiFileHandle *)file;
- (void)setFile: (LiFileHandle *)aFile;
@end
