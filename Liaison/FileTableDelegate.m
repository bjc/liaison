#import "FileTableDelegate.h"

#import "InspectorController.h"
#import "ImageAndTextCell.h"
#import "LoadPanelController.h"
#import "NIBConnector.h"
#import "PluginManager.h"

#include <dirent.h>
#include <sys/types.h>

// XXX - should use SEL instead of NSString.
struct SortContext {
    BOOL ascending;
    SEL compareMethod, getMethod;
};

int contextSorter(id file1, id file2, void *someContext)
{
    struct SortContext *context;
    id leftVal, rightVal;

    context = (struct SortContext *)someContext;
    if (context->ascending) {
        leftVal = [file1 performSelector: context->getMethod];
        rightVal = [file2 performSelector: context->getMethod];
    } else {
        leftVal = [file2 performSelector: context->getMethod];
        rightVal = [file1 performSelector: context->getMethod];
    }

    if (rightVal == nil) {
        if (leftVal == nil)
            return 0;
        else
            return -1;
    } else if (leftVal == nil)
        return 1;

    return (int)[leftVal performSelector: context->compareMethod
                              withObject: rightVal];
}

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTable(aString, @"WindowElements", @"");
}

static void
logRect(NSString *desc, NSRect aRect)
{
    [LiLog logAsDebug: @"%@, (%f, %f, %f, %f)", desc, aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height];
}

@interface LiFileHandle (GUIStuff)
- (void)revealInFinder;
@end

@implementation LiFileStore (BatchPathAdditions)
- (BOOL)isValidPath: (NSString *)aPath
{
    NSString *filename;

    filename = [aPath lastPathComponent];
    if ([filename hasPrefix: @"."] ||
        [filename isEqualToString: @"Icon\r"])
        return NO;

    return YES;
}

- (BOOL)addURLs: (NSArray *)aURLList toGroup: (NSString *)aGroup
{
    NSURL *fileURL;
    int i, numFiles;

    if ([aURLList count] == 0)
        return YES;

    numFiles = [aURLList count];

    i = 0;
    for (fileURL in aURLList) {
        LiFileHandle *tmpFile;

        NS_DURING
            tmpFile = [self addURL: fileURL];

            if (aGroup != nil) {
                [tmpFile addToGroup: aGroup];
            }
        NS_HANDLER
                [LiLog logAsWarning: @"Couldn't add file: %@ - %@", [localException name], [localException reason]];
        NS_ENDHANDLER

        i++;
    }

    return YES;
}

- (NSArray *)makeURLsFromPaths: (NSArray *)aFileList toGroup: (NSString *)aGroup
{
    LoadPanelController *loadPanelController;
    NSMutableArray *myFileList;
    NSString *path;
    int i, fileCount;

    loadPanelController = [[NIBConnector connector] loadPanelController];
    [loadPanelController setStatus: myLocalizedString(@"LiLoadingDirectory")];
    [loadPanelController setProgress: 100.0];
    [loadPanelController setIndeterminantProgress: YES];
    [loadPanelController update];
    fileCount = [aFileList count];
    i = 0;

    myFileList = [NSMutableArray array];
    for (path in aFileList) {
        if ((i % 10) == 0) {
            [loadPanelController setPath: [path lastPathComponent]];
            [loadPanelController update];
        }

        if ([self isValidPath: path]) {
            NSFileManager *defaultManager;
            BOOL isBundle;
            BOOL isDirectory;

            isDirectory = NO;
            defaultManager = [NSFileManager defaultManager];
            [defaultManager fileExistsAtPath: path isDirectory: &isDirectory];
            if ([path hasSuffix: @".app"] ||
                [[NSWorkspace sharedWorkspace] isFilePackageAtPath: path])
                isBundle = YES;
            else
                isBundle = NO;

            if (isDirectory && !isBundle) {
                struct dirent *dirp;
                DIR *directory;
                NSAutoreleasePool *rp;
                NSMutableArray *dirContents;
                int j;

                [LiLog logAsDebug: @"Recursing into: %@", path];
                [LiLog indentDebugLog];

                // Let people know we're working in a subdirectory.
                j = 0;

                dirContents = [[NSMutableArray alloc] init];
                directory = opendir([path UTF8String]);
                while ((dirp = readdir(directory)) != NULL) {
                    NSString *subPath;

                    subPath = [NSString stringWithUTF8String: dirp->d_name];
                    if ([self isValidPath: subPath] == YES) {
                        NSString *fullPath;

                        if ((j % 10) == 0) {
                            [loadPanelController update];
                        }

                        fullPath = [path stringByAppendingPathComponent: subPath];
                        [dirContents addObject: fullPath];
                    }
                    j++;
                }
                closedir(directory);

                rp = [[NSAutoreleasePool alloc] init];
                [self addURLs: [self makeURLsFromPaths: dirContents toGroup: aGroup]
                      toGroup: aGroup];
                [rp release];
                [dirContents release];

                [LiLog unindentDebugLog];
            } else {
                [LiLog logAsDebug: @"Adding %@ to file list", path];
                [loadPanelController setPath: [path lastPathComponent]];
                [myFileList addObject: [NSURL fileURLWithPath: path]];
            }
        }
        i++;
    }

    return myFileList;
}

- (NSArray *)addPaths: (NSArray *)aPathList toGroup: (NSString *)aGroup
{
    if ([aPathList count] > 0) {
        LoadPanelController *loadPanelController;
        NSArray *fileList;

        loadPanelController = [[NIBConnector connector] loadPanelController];
        [loadPanelController show];
        fileList = [self makeURLsFromPaths: aPathList toGroup: aGroup];
        [self addURLs: fileList toGroup: aGroup];
        [loadPanelController hide];
        [self synchronize];
    }

    return nil;
}
@end

@implementation FileTableDelegate (LiTableViewDelegate)
- (void)tableViewDidBecomeFirstResponder: (NSTableView *)aTableView
{
    [LiLog logAsDebug: @"[FileTableDelegate becameFirstResponder]"];
    [LiLog indentDebugLog];
    if ([tableView numberOfSelectedRows] == 1) {
        LiFileHandle *theRecord;

        theRecord = [self fileAtIndex: [tableView selectedRow]];
        // Auto-update a clicked file.
        [theRecord update];
        [[theRecord fileStore] synchronize];
        [inspectorController setFile: theRecord];
    }
    [LiLog unindentDebugLog];
}

- (void)deleteSelectedRowsInTableView: (NSTableView *)aTableView
{
    NSEnumerator *rowEnum;
    NSString *myGroup;
    NSMutableArray *selectedFiles;
    NSNumber *row;

    rowEnum = [aTableView selectedRowEnumerator];
    selectedFiles = [NSMutableArray array];
    while ((row = [rowEnum nextObject]) != nil) {
        LiFileHandle *record;

        record = [self fileAtIndex: [row intValue]];
        [selectedFiles addObject: record];
    }

    [aTableView deselectAll: self];

    myGroup = [self group];
    if (myGroup == nil) {
        LiFileHandle *file;

        for (file in selectedFiles) {
            [[self fileStore] removeFileHandle: file];
        }
    } else {
        LiFileHandle *file;

        for (file in selectedFiles) {
            [LiLog logAsDebug: @"Removing %@ from %@", [file filename], myGroup];
            [LiLog logAsDebug: @"old groups: %@", [[file groups] description]];
            [file removeFromGroup: myGroup];
            [LiLog logAsDebug: @"new groups: %@", [[file groups] description]];
        }
    }
    [[self fileStore] synchronize];
}
@end

@implementation FileTableDelegate (TableViewDataSource)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[self sortedList] count];
}

- (id)tableView: (NSTableView *)aTableView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
            row: (int)rowIndex
{
    LiFileHandle *record;
    LiBrowserColumn *col;

    col = [self columnForIdentifier: [aTableColumn identifier]];
    record = [self fileAtIndex: rowIndex];
    return [col objectForRecord: record];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    LiFileHandle *record;
    LiBrowserColumn *col;

    if (rowIndex < 0 || rowIndex >= (int)[[self sortedList] count])
        return;

    col = [self columnForIdentifier: [aTableColumn identifier]];
    record = [self fileAtIndex: rowIndex];
    [col setObject: anObject forRecord: record];

    [[record fileStore] synchronize];
}

- (NSDragOperation)tableView: (NSTableView *)aTableView
                validateDrop: (id <NSDraggingInfo>)sender
                 proposedRow: (int)index
       proposedDropOperation: (NSDragOperation)operation;
{
    NSDragOperation dragOp;

    dragOp = NSDragOperationNone;
    if ([sender draggingSource] != tableView &&
        [[self fileStore] isEditable] == YES) {
        NSPasteboard *pboard;

        pboard = [sender draggingPasteboard];
        if ([pboard availableTypeFromArray:
            [NSArray arrayWithObjects: NSFilenamesPboardType, NSFilesPromisePboardType, nil]]) {
            [aTableView setDropRow: -1 dropOperation: NSTableViewDropOn];
            dragOp = NSDragOperationCopy;
        }
    }

    return dragOp;
}

- (BOOL)tableView: (NSTableView *)aTableView
       acceptDrop: (id <NSDraggingInfo>)aSender
              row: (int)anIndex
    dropOperation: (NSTableViewDropOperation)anOperation
{
    NSArray *pathList;
    NSPasteboard *pboard;

    pboard = [aSender draggingPasteboard];

    pathList = nil;
    if ([pboard availableTypeFromArray:
        [NSArray arrayWithObject: NSFilenamesPboardType]]) {
        pathList = [pboard propertyListForType: NSFilenamesPboardType];
    }

    // Handle promised files.
    if ([[pboard types] containsObject: NSFilesPromisePboardType]) {
        NSEnumerator *pathEnum;
        NSMutableArray *promisedPaths;
        NSString *path;
        NSURL *dropLocation;

        dropLocation = [NSURL fileURLWithPath:
            [[Preferences sharedPreferences] downloadDirectory]];
        pathEnum = [[aSender namesOfPromisedFilesDroppedAtDestination: dropLocation] objectEnumerator];
        promisedPaths = [NSMutableArray array];
        while ((path = [pathEnum nextObject]) != nil) {
            [promisedPaths addObject: [[dropLocation path] stringByAppendingPathComponent: path]];
        }
        pathList = promisedPaths;
    }

    if ([pathList count] > 0) {
        [[self fileStore] addPaths: pathList toGroup: [self group]];
        return YES;
    }

    // XXX - should select the added songs now.

    return NO;

}

- (BOOL)tableView: (NSTableView *)aTableView
        writeRows: (NSArray *)someRows
     toPasteboard: (NSPasteboard *)aPboard
{
    NSMutableArray *liaisonPboard, *filenamePboard, *promisePboard;
    NSMutableArray *typeList;
    NSNumber *row;

    liaisonPboard = [NSMutableArray array];
    filenamePboard = [NSMutableArray array];
    promisePboard = [NSMutableArray array];

    for (row in someRows) {
        LiFileHandle *file;
        NSURL *url;

        file = [self fileAtIndex: [row intValue]];
        [liaisonPboard addObject: file];
        url = [file url];
        if ([url isFileURL] == YES) {
            [filenamePboard addObject: [url path]];
        }
    }

    typeList = [NSMutableArray array];
    if ([liaisonPboard count] > 0)
        [typeList addObject: LiaisonPboardType];
    if ([filenamePboard count] > 0)
        [typeList addObject: NSFilenamesPboardType];
    // Make an HFS promise.

    if ([typeList count] > 0) {
        [aPboard declareTypes: typeList owner: self];

        if ([liaisonPboard count] > 0) {
            NSData *liaisonPboardData;

            liaisonPboardData = [NSKeyedArchiver archivedDataWithRootObject:
                liaisonPboard];
            if ([aPboard setData: liaisonPboardData
                         forType: LiaisonPboardType] == NO)
                return NO;
        }

        if ([filenamePboard count] > 0) {
            if ([aPboard setPropertyList: filenamePboard
                                 forType: NSFilenamesPboardType] == NO)
                return NO;
        }
        return YES;
    }
    return NO;
}
@end

@implementation FileTableDelegate (TableViewDelegate)
- (void)tableView: (NSTableView*)aTableView
didClickTableColumn: (NSTableColumn *)aTableColumn
{
    LiBrowserColumn *col;

    col = [self columnForIdentifier: [aTableColumn identifier]];
    if ([col compareMethod]) {
        struct SortContext context;

        if ([self selectedColumn] && [self selectedColumn] == aTableColumn) {
            if (isAscending)
                isAscending = NO;
            else
                aTableColumn = nil; // XXX, but it works.
        } else
            isAscending = YES;
        
        context.ascending = isAscending;
        context.getMethod = [col getMethod];
        context.compareMethod = [col compareMethod];
        [self saveSelectionOfTableView: tableView];
        [self setSelectedColumn: aTableColumn withContext: &context];
        [self redisplay];
        [self restoreSelectionToTableView: tableView refresh: YES];
    }
}

- (BOOL)tableView: (NSTableView *)theTable shouldSelectRow: (int)theRow
{
    if (theRow < 0 || (int)[[self sortedList] count] <= theRow)
        return NO;
    return YES;
}

- (BOOL)tableView: (NSTableView *)aTableView
shouldEditTableColumn: (NSTableColumn *)aTableColumn
              row: (int)rowIndex
{
    LiFileHandle *record;

    record = [self fileAtIndex: rowIndex];
    return [record isEditable];
}

- (void)tableView: (NSTableView *)aTableView
          copyRow: (int)aRow
{
    [LiLog logAsDebug: @"[tableView copyRow]"];
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification
{
    [LiLog logAsDebug: @"[FileTableDelegate tableViewSelectionDidChange: (notification)]"];
    [LiLog indentDebugLog];
    if ([tableView numberOfSelectedRows] == 1) {
        LiFileHandle *theRecord;

        theRecord = [self fileAtIndex: [tableView selectedRow]];
        // Auto-update a clicked file.
        [theRecord update];
        [[theRecord fileStore] synchronize];
        [inspectorController setFile: theRecord];
    }
    [LiLog unindentDebugLog];
}

- (void)doDoubleClickInTable: (NSTableView *)aTable;
{
    NSEnumerator *rowEnum;
    NSNumber *selectedRow;

    rowEnum = [aTable selectedRowEnumerator];
    while ((selectedRow = [rowEnum nextObject]) != nil) {
        LiFileHandle *file;

        file = [self fileAtIndex: [selectedRow intValue]];
        [file open];
    }
}

- (void)tableViewColumnDidMove: (NSNotification *)aNotification
{
    NSEnumerator *colEnum;
    NSMutableArray *colOrder;
    NSMutableDictionary *listPrefs;
    NSTableColumn *column;

    listPrefs = [self listPrefs];
    colOrder = [NSMutableArray array];
    colEnum = [[[self tableView] tableColumns] objectEnumerator];
    while ((column = [colEnum nextObject]) != nil) {
        [colOrder addObject: [column identifier]];
    }

    [listPrefs setObject: colOrder forKey: @"columnOrder"];
    [self setListPrefs: listPrefs];
}

- (void)tableViewColumnDidResize: (NSNotification *)aNotification
{
    NSMutableDictionary *colPrefs;
    NSNumber *colSize;
    NSTableColumn *column;

    column = [[aNotification userInfo] objectForKey: @"NSTableColumn"];
    if (column != nil) {
        colPrefs = [self columnPrefsForIdentifier: [column identifier]];
        colSize = [NSNumber numberWithFloat: [column width]];
        [colPrefs setObject: colSize forKey: @"width"];
        [self setColumnPrefs: colPrefs forIdentifier: [column identifier]];
    }
}
@end

@implementation FileTableDelegate
- (void)openPanelDidEnd: (NSOpenPanel *)openPanel
             returnCode: (int)returnCode
            contextInfo: (void *)context
{
    [openPanel close];
    if (returnCode == NSOKButton) {
        [[self fileStore] addPaths: [openPanel filenames] toGroup: [self group]];
    }
}

- (IBAction)addFiles: (id)sender
{
    NSOpenPanel *openPanel;

    if ([[self fileStore] isEditable]) {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setTitle: myLocalizedString(@"LiLoadPanelTitle")];
        [openPanel setAllowsMultipleSelection: YES];
        [openPanel setCanChooseDirectories: YES];
        [openPanel setCanChooseFiles: YES];

        [openPanel beginSheetForDirectory: nil file: nil types: nil
                           modalForWindow: [NSApp mainWindow] modalDelegate: self
                           didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                              contextInfo: nil];
    }
}

- (IBAction)openSelectedFiles: (id)sender
{
    NSEnumerator *selectionEnum;
    NSNumber *row;

    selectionEnum = [tableView selectedRowEnumerator];
    while ((row = [selectionEnum nextObject]) != nil) {
        LiFileHandle *fileHandle;

        fileHandle = [self fileAtIndex: [row intValue]];
        [fileHandle open];
    }
}

- (IBAction)revealInFinder: (id)sender
{
    NSEnumerator *rowEnum;
    NSNumber *row;

    rowEnum = [tableView selectedRowEnumerator];
    while ((row = [rowEnum nextObject]) != nil) {
        LiFileHandle *tmpFile;

        tmpFile = [self fileAtIndex: [row intValue]];
        [tmpFile revealInFinder];
    }
}

- (NSDictionary *)browserColumns
{
    NSEnumerator *pluginEnum;
    NSMutableDictionary *browserColumns;
    NSObject <LiBrowserPlugin> *plugin;

    browserColumns = [NSMutableDictionary dictionary];
    pluginEnum = [[[PluginManager defaultManager] browserPlugins] objectEnumerator];
    while ((plugin = [pluginEnum nextObject]) != nil) {
        LiBrowserColumn *col;
        NSEnumerator *colEnum;

        colEnum = [[plugin columns] objectEnumerator];
        while ((col = [colEnum nextObject]) != nil) {
            NSString *identifier;

            identifier = [NSString stringWithFormat: @"%@:%@",
                NSStringFromClass([plugin class]), [col identifier]];
            [browserColumns setObject: col forKey: identifier];
        }
    }

    return browserColumns;
}

- (LiBrowserColumn *)columnForIdentifier: (NSString *)anIdentifier
{
    return [theTableColumns objectForKey: anIdentifier];
}

- (void)showColumnWithIdentifier: (NSString *)anIdentifier
{
    LiBrowserColumn *col;
    NSMutableDictionary *shownColumns;

    shownColumns = [self shownColumns];
    if (shownColumns == nil) {
        shownColumns = [NSMutableDictionary dictionary];
        [self setShownColumns: shownColumns];
    }
    
    col = [self columnForIdentifier: anIdentifier];
    if (col && [shownColumns objectForKey: anIdentifier] == nil) {
        NSDictionary *colPrefs;
        NSTableColumn *tableColumn;

        colPrefs = [self columnPrefsForIdentifier: anIdentifier];
        tableColumn = [[[NSTableColumn alloc] initWithIdentifier: anIdentifier] autorelease];
        [tableColumn setEditable: [col editable]];
        [tableColumn setDataCell: [col cell]];
        [tableColumn setResizable: [col resizable]];
        if ([col resizable]) {
            NSNumber *colWidth;

            colWidth = [colPrefs objectForKey: @"width"];
            if (colWidth != nil)
                [col setWidth: colWidth];
        }
        
        if ([col showsHeader])
            [[tableColumn headerCell] setStringValue: [col name]];
        else
            [[tableColumn headerCell] setStringValue: @""];

        if ([col width])
            [tableColumn setWidth: [[col width] floatValue]];

        [shownColumns setObject: tableColumn forKey: anIdentifier];
        
        [tableView addTableColumn: tableColumn];
    }
}

- (void)removeColumnWithIdentifier: (NSString *)anIdentifier
{
    NSTableColumn *col;

    col = [[self shownColumns] objectForKey: anIdentifier];
    if (col != nil) {
        [[self shownColumns] removeObjectForKey: anIdentifier];
        [tableView removeTableColumn: col];
    }
}

- (id)init
{
    self = [super init];

    theTableColumns = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];

    [ascendingSortingImage release];
    [descendingSortingImage release];
    [self setActiveList: nil];
    [self setFileStore: nil];
    [self setFilter: nil];
    [self setSearchString: nil];

    [theTableColumns release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    NSArray *shownColumns;
    NSDictionary *listPrefs;
    NSEnumerator *columnEnum;
    NSString *columnID;

    [LiLog logAsDebug: @"[FileTableDelegate awakeFromNib]"];
    [LiLog indentDebugLog];

    ascendingSortingImage = [[NSImage imageNamed: @"SortAscending.gif"] retain];
    descendingSortingImage = [[NSImage imageNamed: @"SortDescending.gif"] retain];

    [tableView setTarget: self];
    [tableView setDoubleAction: @selector(doDoubleClickInTable:)];

    // XXX
    theTableColumns = (NSMutableDictionary *)[self browserColumns];
    [theTableColumns retain];
    
    listPrefs = [self listPrefs];
    shownColumns = [listPrefs objectForKey: @"columnOrder"];
    for (columnID in shownColumns) {
        [self showColumnWithIdentifier: columnID];
    }

    if ([[[self tableView] tableColumns] count] == 0) {
        columnEnum = [theTableColumns keyEnumerator];
        while ((columnID = [columnEnum nextObject]) != nil) {
            [LiLog logAsDebug: @"showCol: %@", columnID];
            [self showColumnWithIdentifier: columnID];
        }
    }
    
    /* Register for Drag-and-Drop operation. */
    [tableView registerForDraggedTypes:
        [NSArray arrayWithObjects: NSFilenamesPboardType, NSFilesPromisePboardType, NSHTMLPboardType, NSTIFFPboardType, NSPICTPboardType, NSURLPboardType, NSFileContentsPboardType, nil]];
    
    [statusLine setStringValue: @""];

    [LiLog unindentDebugLog];
}

- (void)respondToFileChanged: (NSNotification *)aNotification
{
    LiFileHandle *file;
    NSArray *addedFileList, *changedFileList, *removedFileList;
    NSDictionary *fileDict;
    NSEnumerator *fileEnum;
    BOOL needsRedisplay;

    needsRedisplay = NO;

    addedFileList = [[aNotification userInfo] objectForKey: LiFilesAdded];
    changedFileList = [[aNotification userInfo] objectForKey: LiFilesChanged];
    removedFileList = [[aNotification userInfo] objectForKey: LiFilesRemoved];

    fileEnum = [addedFileList objectEnumerator];
    while (needsRedisplay == NO &&
           (file = [fileEnum nextObject]) != nil) {
        if ([file matchesFilter: [self filter]])
            needsRedisplay = YES;
    }

    fileEnum = [changedFileList objectEnumerator];
    while (needsRedisplay == NO &&
           (fileDict = [fileEnum nextObject]) != nil) {
        LiFileHandle *tmpHandle;
        NSDictionary *oldAttributes;
        
        tmpHandle = [fileDict objectForKey: @"LiFileHandleAttribute"];
        oldAttributes = [fileDict objectForKey: LiFileOldAttributes];
        if ([[self fileStore] attributes: oldAttributes matchFilter: [self filter]] ||
            [tmpHandle matchesFilter: [self filter]])
            needsRedisplay = YES;
    }

    fileEnum = [removedFileList objectEnumerator];
    while (needsRedisplay == NO &&
           (fileDict = [fileEnum nextObject]) != nil) {
        if ([[self fileStore] attributes: [fileDict objectForKey: LiFileOldAttributes]
                             matchFilter: [self filter]]) {
            needsRedisplay = YES;
        }
    }

    if (needsRedisplay) {
        [self saveSelectionOfTableView: tableView];
        [self redisplay];
        [self restoreSelectionToTableView: tableView refresh: YES];
    }
}

- (int)numberOfFiles
{
    return [[self sortedList] count];
}

- (LiFileHandle *)fileAtIndex: (int)index
{
    return [[self sortedList] objectAtIndex: index];
}

- (void)addAttributeFilter: (LiFilter *)aFilter
{
    [LiLog logAsDebug: @"[FileTableDelegate addAttributeFilter: %@]", [aFilter description]];
    [LiLog indentDebugLog];

    [self setFilter: aFilter];
    
#if 0
    filters = [self attributeFilters];
    attrEnum = [someFilters keyEnumerator];
    while ((attribute = [attrEnum nextObject]) != nil)
        [filters setObject: [someFilters objectForKey: attribute]
                    forKey: attribute];

    [LiLog unindentDebugLog];
#endif
}

#if 0
- (id)filterForAttribute: (NSString *)anAttribute
{
    [LiLog logAsDebug: @"[FileTableDelegate filterForAttribute: %@]", anAttribute];
    [[LiLog indentDebugLog] logAsDebug: @"filters: %@", [[self attributeFilters] description]];
    [LiLog unindentDebugLog];
    return [[self attributeFilters] objectForKey: anAttribute];
}
#endif

- (void)removeAttributeFilter: (LiFilter *)aFilter
{
    [LiLog logAsDebug: @"[FileTableDelegate removeAttributeFilter: %@]", [aFilter description]];
    [self setFilter: nil];
    
#if 0
    filters = [self attributeFilters];
    attrEnum = [someFilters keyEnumerator];
    while ((attribute = [attrEnum nextObject]) != nil)
        [filters removeObjectForKey: attribute];
#endif
}

- (void)saveSelectionOfTableView: (NSTableView *)aTableView
{
    NSEnumerator *theEnum;
    NSMutableSet *savedSelection;
    NSNumber *rowNum;

    savedSelection = [self savedSelection];
    if (savedSelection == nil) {
        savedSelection = [[NSMutableSet alloc] init];
        theEnum = [aTableView selectedRowEnumerator];
        while ((rowNum = [theEnum nextObject]) != nil) {
            id item;

            item = [[self sortedList] objectAtIndex: [rowNum intValue]];
            [savedSelection addObject: item];
        }
        [self setSavedSelection: savedSelection];
    }
}

- (void)restoreSelectionToTableView: (NSTableView *)aTableView
                            refresh: (BOOL)inRefresh
{
    NSMutableSet *savedSelection;
    id item;
    int savedLastRow;

    [aTableView deselectAll: self];
    
    savedLastRow = -1;
    savedSelection = [self savedSelection];
    if (savedSelection != nil) {
        for (item in savedSelection) {
            int row;

            row = [[self sortedList] indexOfObject: item];
            if (row != NSNotFound) {
                [aTableView selectRow: row byExtendingSelection: YES];
                savedLastRow = row;
            }
        }

        [self setSavedSelection: nil];

        if (inRefresh && savedLastRow > -1)
            [aTableView scrollRowToVisible: savedLastRow];
    }
}

- (NSSize)minSize
{
    NSArray *tableColumns;
    NSRect headerRect;
    NSTableColumn *column;
    float minHeight, minWidth, rowHeight, scrollHeight, scrollWidth;
    int numRows;

    [LiLog logAsDebug: @"[FileTableDelegate minSize]"];
    [LiLog indentDebugLog];

    headerRect = [[[self tableView] headerView] frame];
    logRect(@"headerRect", headerRect);

    rowHeight = [[self tableView] rowHeight];
    [LiLog logAsDebug: @"row height: %f", rowHeight];
    numRows = [self numberOfRowsInTableView: [self tableView]];
    [LiLog logAsDebug: @"number of rows: %d", numRows];
    
    scrollWidth = 17.0;
    scrollHeight = 34.0;

    tableColumns = [[self tableView] tableColumns];
    minWidth = scrollWidth;
    [LiLog indentDebugLog];
    for (column in tableColumns) {
        float colWidth;

        colWidth = [column width];
        [LiLog logAsDebug: @"colWidth: %f", colWidth];
        minWidth += colWidth;
    }
    [LiLog unindentDebugLog];
    [LiLog logAsDebug: @"minWidth: %f", minWidth];
    
    minHeight = headerRect.size.height + rowHeight * numRows + scrollHeight;
    [LiLog logAsDebug: @"minHeight: %f", minHeight];

    [LiLog unindentDebugLog];
    return NSMakeSize(minWidth, minHeight);
}


- (BOOL)validateAction: (SEL)anAction
{
    //[LiLog logAsDebug: @"[FileTableDelegate validateAction: %@]", NSStringFromSelector(anAction)];
    if (anAction == @selector(addFiles:)) {
        return [[self fileStore] isEditable];
    } else if (anAction == @selector(delete:)) {
        return ([[self fileStore] isEditable] &&
                [tableView numberOfSelectedRows] > 0);
    } else if (anAction == @selector(revealInFinder:)) {
        return ([[self fileStore] isEditable] &&
                [tableView numberOfSelectedRows] > 0);
    } else if (anAction == @selector(openSelectedFiles:)) {
        return ([[self fileStore] isEditable] &&
                [tableView numberOfSelectedRows] > 0);
    } else
        return YES;
}

- (BOOL)validateMenuItem: (NSMenuItem *)anItem
{
    return [self validateAction: [anItem action]];
}

- (void)redisplay
{
    NSString *filePlural;
    unsigned long numRecords;

    [self setSearchString: [self searchString]];
    [self setSelectedColumn: [self selectedColumn]];

    numRecords = [[self sortedList] count];
    if (numRecords == 1) {
        filePlural = myLocalizedString(@"LiFileSingular");
    } else {
        filePlural = myLocalizedString(@"LiFilePlural");
    }
    [statusLine setStringValue:
        [NSString stringWithFormat: @"(%d %@)", numRecords, filePlural]];

    [tableView reloadData];
}
@synthesize statusLine;
@synthesize theTableColumns;
@synthesize theFileStore;
@synthesize theListPrefs;
@synthesize isAscending;
@synthesize tableView;
@synthesize theContextMenu;
@synthesize theFilter;
@synthesize theSavedSelection;
@synthesize theShownColumns;
@synthesize theSelectedColumn;
@synthesize inspectorController;
@synthesize theSearchString;
@end

@implementation FileTableDelegate (CommonAccessors)
#if 0
- (NSString *)group
{
    return [self filterForAttribute: LiGroupsAttribute];
}

- (void)setGroup: (NSString *)aGroupName
{
    if (aGroupName == nil) {
        if ([self group] != nil) {
            NSDictionary *filter;

            filter = [NSDictionary dictionaryWithObject: [self group]
                                                 forKey: LiGroupsAttribute];
            [self removeAttributeFilters: filter];
        }
    } else {
        NSDictionary *filter;

        filter = [NSDictionary dictionaryWithObject: aGroupName
                                             forKey: LiGroupsAttribute];
        [self addAttributeFilters: filter];
    }
    // We're re-filtering.
    [self setActiveList: nil];

    [self redisplay];
}
#endif

- (NSString *)group
{
    return [[self filter] value];
}

- (void)setGroup: (NSString *)aGroup
{
    LiFilter *filter;

    if (aGroup != nil)
        filter = [LiFilter filterWithAttribute: LiGroupsAttribute
                               compareSelector: @selector(isEqual:)
                                         value: aGroup];
    else
        filter = nil;
    [self setFilter: filter];
}
@end

@implementation FileTableDelegate (Accessors)
- (LiFileStore *)fileStore
{
    return theFileStore;
}

- (void)setFileStore: (LiFileStore *)aFileStore
{
    [LiLog logAsDebug: @"[FileTableDelegate setFileStore: %@]", aFileStore];

    if (aFileStore != theFileStore) {
        NSNotificationCenter *defaultCenter;
        
        defaultCenter = [NSNotificationCenter defaultCenter];
        if (theFileStore != nil) {
            [defaultCenter removeObserver: self
                                     name: LiFileChangedNotification
                                   object: theFileStore];
            [theFileStore release];
        }
        if (aFileStore != nil) {
            [defaultCenter addObserver: self
                              selector: @selector(respondToFileChanged:)
                                  name: LiFileChangedNotification
                                object: aFileStore];
            theFileStore = [aFileStore retain];
        }
    }
}

#if 0
- (NSMutableDictionary *)attributeFilters
{
    return theFilters;
}

- (void)setAttributeFilters: (NSMutableDictionary *)someFilters
{
    if (someFilters != theFilters) {
        [someFilters retain];
        [theFilters release];
        theFilters = someFilters;
    }
}
#endif

- (LiFilter *)filter
{
    return theFilter;
}

- (void)setFilter: (LiFilter *)aFilter
{
    [aFilter retain];
    [theFilter retain];
    theFilter = aFilter;
}

- (NSMutableDictionary *)shownColumns
{
    return theShownColumns;
}

- (void)setShownColumns: (NSMutableDictionary *)someColumns
{
    [someColumns retain];
    [theShownColumns release];
    theShownColumns = someColumns;
}

- (NSArray *)sortedList
{
    if (theSortedList == nil)
        return [self activeList];
    else
        return theSortedList;
}

- (void)setSortedList: (NSArray *)aFileList
{
    [aFileList retain];
    [theSortedList release];
    theSortedList = aFileList;
}

- (NSArray *)activeList
{
    if (theActiveList == nil)
        return [self fileList];
    else
        return theActiveList;
}

- (void)setActiveList: (NSArray *)aFileList
{
    if (aFileList != theActiveList) {
        [aFileList retain];
        [theActiveList release];
        theActiveList = aFileList;

        [self setSortedList: nil];
    }
}

- (NSArray *)fileList
{
    return [[self fileStore] filesMatchingFilter: [self filter]];
}

- (NSString *)searchString
{
    return theSearchString;
}

- (NSArray *)filter: (NSArray *)aFileList
           byString: (NSString *)aSearchString
{
    LiFileHandle *record;
    NSMutableArray *subset;

    if ([aSearchString length] == 0)
        return aFileList;

    subset = [NSMutableArray array];
    for (record in aFileList) {
        NSString *filename;
        NSRange range;

        filename = [[record filename] lowercaseString];
        range = [filename rangeOfString: aSearchString];
        if (range.location != NSNotFound)
            [subset addObject: record];
    }

    return subset;
}

- (void)setSearchString: (NSString *)aSearchString
{
    NSArray *tmpList;

    if (aSearchString == nil) {
        aSearchString = @"";
        tmpList = [self fileList];
    } else if ([aSearchString rangeOfString: theSearchString options: NSCaseInsensitiveSearch].location != NSNotFound) {
        // Optimized filter - only need to select off the active list.
        tmpList = [self filter: [self activeList] byString: aSearchString];
    } else {
        tmpList = [self filter: [self fileList] byString: aSearchString];
    }

    [aSearchString retain];
    [theSearchString release];
    theSearchString = aSearchString;

    [self setActiveList: tmpList];
}

- (NSTableColumn *)selectedColumn
{
    return theSelectedColumn;
}

- (void)setSelectedColumn: (NSTableColumn *)aColumn
{
    LiBrowserColumn *col;
    struct SortContext context;

    col = [self columnForIdentifier: [aColumn identifier]];
    
    context.ascending = isAscending;
    context.getMethod = [col getMethod];
    context.compareMethod = [col compareMethod];
    [self setSelectedColumn: aColumn withContext: &context];
}

- (void)setSelectedColumn: (NSTableColumn *)aColumn
              withContext: (void *)someContext
{
    struct SortContext *context;
    NSArray *sortedList;

    [aColumn retain];
    [theSelectedColumn release];
    theSelectedColumn = aColumn;

    context = (struct SortContext *)someContext;

    if ([tableView highlightedTableColumn] != theSelectedColumn) {
        [tableView setIndicatorImage: nil
                       inTableColumn: [tableView highlightedTableColumn]];
    }

    [tableView setHighlightedTableColumn: theSelectedColumn];
    if (theSelectedColumn != nil) {
        if (context->ascending)
            [tableView setIndicatorImage: ascendingSortingImage
                           inTableColumn: theSelectedColumn];
        else
            [tableView setIndicatorImage: descendingSortingImage
                           inTableColumn: theSelectedColumn];

        sortedList = [[self activeList] sortedArrayUsingFunction: contextSorter
                                                         context: someContext];

        [self setSortedList: sortedList];
    } else {
        [self setSortedList: nil];
    }
}

- (NSMutableSet *)savedSelection
{
    return theSavedSelection;
}

- (void)setSavedSelection: (NSMutableSet *)aSelection
{
    [aSelection retain];
    [theSavedSelection release];
    theSavedSelection = aSelection;
}

- (NSMutableDictionary *)listPrefs
{
    if (theListPrefs == nil) {
        NSDictionary *listPrefs;
        
        listPrefs = [[Preferences sharedPreferences] fileListPrefs];
        if (listPrefs != nil) {
            theListPrefs = [[NSMutableDictionary alloc] initWithDictionary: listPrefs];
        } else
            theListPrefs = [[NSMutableDictionary alloc] init];
    }
    return theListPrefs;
}

- (void)setListPrefs: (NSMutableDictionary *)listPrefs
{
    [listPrefs retain];
    [theListPrefs release];
    theListPrefs = listPrefs;

    [[Preferences sharedPreferences] setFileListPrefs: theListPrefs];
}

- (NSMutableDictionary *)columnPrefsForIdentifier: (NSString *)anIdentifier
{
    NSMutableDictionary *colPrefs, *retVal;

    colPrefs = [[self listPrefs] objectForKey: @"columns"];
    if (colPrefs == nil) {
        colPrefs = [NSMutableDictionary dictionary];
        [[self listPrefs] setObject: colPrefs forKey: @"columns"];
    }

    retVal = [colPrefs objectForKey: anIdentifier];
    if (retVal == nil) {
        retVal = [NSMutableDictionary dictionary];
        [colPrefs setObject: retVal forKey: anIdentifier];
    }

    return retVal;
}

- (void)setColumnPrefs: (NSMutableDictionary *)columnPrefs
         forIdentifier: (NSString *)anIdentifier
{
    NSMutableDictionary *colPrefs;

    colPrefs = [[self listPrefs] objectForKey: @"columns"];
    if (colPrefs == nil) {
        colPrefs = [NSMutableDictionary dictionary];
        [[self listPrefs] setObject: colPrefs forKey: @"columns"];
    }

    [colPrefs setObject: columnPrefs forKey: anIdentifier];

    [[Preferences sharedPreferences] setFileListPrefs: theListPrefs];
}

- (NSTableView *)tableView
{
    return tableView;
}
@end

@implementation LiFileHandle (GUIStuff)
- (void)revealInFinder
{
    NSURL *fileURL;

    fileURL = [self url];
    if ([fileURL isFileURL]) {
        [[NSWorkspace sharedWorkspace] selectFile:
          [fileURL path] inFileViewerRootedAtPath: @""];
    }
}
@end