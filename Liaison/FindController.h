//
//  FindController.h
//  Liaison
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface FindController : NSObject
{
    IBOutlet NSBox *theFilterBox;
    IBOutlet NSTableView *theFileList;
    IBOutlet NSView *theFindView;
    IBOutlet NSWindow *theFindWindow;
    IBOutlet NSPopUpButton *theLibraryPopUp;
    IBOutlet NSPopUpButton *theOperatorPopUp;

    LiFilter *theFilter;

    NSMutableDictionary *theTableColumns;
}
- (IBAction)showWindow: (id)sender;

- (IBAction)libraryUpdated: (id)sender;

- (IBAction)addFilterRow: (id)sender;
- (IBAction)removeFilterRow: (id)sender;
@property (retain) NSPopUpButton *theOperatorPopUp;
@property (retain,getter=filter) LiFilter *theFilter;
@property (retain,getter=tableColumns) NSMutableDictionary *theTableColumns;
@property (retain) NSView *theFindView;
@property (retain) NSWindow *theFindWindow;
@property (retain) NSPopUpButton *theLibraryPopUp;
@property (retain) NSBox *theFilterBox;
@property (retain) NSTableView *theFileList;
@end

@interface FindController (Accessors)
- (LiFilter *)filter;
- (void)setFilter: (LiFilter *)aFilter;
- (NSMutableDictionary *)tableColumns;
- (void)setTableColumns: (NSMutableDictionary *)someColumns;
@end