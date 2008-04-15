//
//  FindController.m
//  Liaison
//
//  Created by Brian Cully on Sat Aug 23 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "FindController.h"

#import "FileTableDelegate.h"

@implementation FindController (WindowDelegate)
- (void)windowDidBecomeKey: (NSNotification *)aNotificatin
{
    [LiLog logAsDebug: @"[FindController windowDidBecomeKey]"];
    [[theFindWindow firstResponder] becomeFirstResponder];
}
@end

@implementation FindController
- (id)init
{
    self = [super init];
    if (self != nil) {
        NSNotificationCenter *defaultCenter;
        
        defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver: self
                          selector: @selector(respondToFileStoreChanged:)
                              name: LiFileStoresChangedNotification
                            object: nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];
    
    [self setFilter: nil];
    [self setTableColumns: nil];
    
    [super dealloc];
}

- (IBAction)showWindow: (id)sender
{
    FileTableDelegate *fileDelegate;

    [LiLog logAsDebug: @"[FindController showWindow: (sender)]"];

    fileDelegate = [theFileList delegate];
    [fileDelegate setFileStore: [[LiFileStore allFileStores] objectAtIndex: 0]];
    [fileDelegate setGroup: nil];

    [theFindWindow makeKeyAndOrderFront: self];
}

- (IBAction)libraryUpdated: (id)sender
{
    LiFileStore *selectedStore;
    int itemTag;

    itemTag = [[theLibraryPopUp selectedItem] tag];
    selectedStore = [LiFileStore fileStoreWithID: [NSNumber numberWithInt: itemTag]];
    if (selectedStore != nil) {
        FileTableDelegate *fileDelegate;

        [LiLog logAsDebug: @"Selected store: %@", [selectedStore name]];
        fileDelegate = [theFileList delegate];
        [fileDelegate setFileStore: selectedStore];
        [fileDelegate setGroup: nil];
    }
}

- (IBAction)addFilterRow: (id)sender
{
    [LiLog logAsDebug: @"[FindController addFilterRow: (sender)]"];
}

- (IBAction)removeFilterRow: (id)sender
{
    [LiLog logAsDebug: @"[FindController removeFilterRow: (sender)]"];
}
@synthesize theLibraryPopUp;
@synthesize theFilter;
@synthesize theFileList;
@synthesize theFindView;
@synthesize theTableColumns;
@synthesize theFindWindow;
@synthesize theFilterBox;
@synthesize theOperatorPopUp;
@end

@implementation FindController (Accessors)
- (LiFilter *)filter
{
    return theFilter;
}

- (void)setFilter: (LiFilter *)aFilter
{
    [aFilter retain];
    [theFilter release];
    aFilter = theFilter;
}

- (NSMutableDictionary *)tableColumns
{
    return theTableColumns;
}

- (void)setTableColumns: (NSMutableDictionary *)someColumns
{
    [someColumns retain];
    [theTableColumns release];
    theTableColumns = someColumns;
}
@end

@implementation FindController (Private)
- (void)respondToFileStoreChanged: (NSNotification *)aNotification
{
    LiFileStore *fileStore;
    NSEnumerator *fsEnum;
    NSMenu *libraryMenu;
    int i;

    [LiLog logAsDebug: @"[FindController respondToFileStoreChanged: (notification)]"];
    [LiLog indentDebugLog];

    libraryMenu = [[[NSMenu alloc] initWithTitle: @"Libraries"] autorelease];
    i = 0;
    fsEnum = [LiFileStore fileStoreEnumerator];
    for (i = 0; (fileStore = [fsEnum nextObject]) != nil; i++) {
        NSMenuItem *fsItem;

        [LiLog logAsDebug: @"found file store: %@", [fileStore name]];
        fsItem = [[[NSMenuItem alloc] initWithTitle: [fileStore name]
                                             action: nil
                                      keyEquivalent: @""] autorelease];
        [fsItem setImage: [fileStore icon]];
        [fsItem setTag: [[fileStore storeID] intValue]];
        [libraryMenu insertItem: fsItem atIndex: i];
    }
    [theLibraryPopUp setMenu: libraryMenu];

    [LiLog unindentDebugLog];
}
@end