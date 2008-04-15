#import "GroupTableDelegate.h"

#import "FileTableDelegate.h"
#import "Group.h"
#import "ImageAndTextCell.h"
#import "WindowController.h"

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTable(aString, @"WindowElements", @"");
}

@interface GroupTableDelegate (Private)
- (BOOL)groupIsLibrary: (Group *)aGroup;
@end

@implementation GroupTableDelegate (LiTableViewDelegate)
- (void)outlineViewDidBecomeFirstResponder: (NSOutlineView *)anOutlineView
{
    [LiLog logAsDebug: @"[GroupTableDelegate becameFirstResponder]"];
}

- (void)deleteSelectedRowsInOutlineView: (NSOutlineView *)anOutlineView
{
    Group *removedGroup;
    int selectedRow;

    selectedRow = [outlineView selectedRow] - 1;

    removedGroup = [anOutlineView itemAtRow: [anOutlineView selectedRow]];
    if ([self groupIsLibrary: removedGroup] == NO) {
        LiFileHandle *file;
        LiFilter *groupFilter;
        NSArray *filesInGroup;
        NSDictionary *removedGroupAttribute;
        NSString *groupname;

        groupname = [removedGroup name];
        groupFilter = [LiFilter filterWithAttribute: LiGroupsAttribute
                                    compareSelector: @selector(isEqual:)
                                              value: groupname];

        filesInGroup = [[removedGroup fileStore] filesMatchingFilter: groupFilter];
        for (file in filesInGroup) {
            [file removeFromGroup: groupname];
        }

        removedGroupAttribute = [NSDictionary dictionaryWithObject: groupname
                                                            forKey: LiGroupsAttribute];
        [[[removedGroup fileStore] delegate] removeDefaultAttribute: removedGroupAttribute
                                                      fromFileStore: [removedGroup fileStore]];

        [[removedGroup parent] removeChild: removedGroup];

        [[removedGroup fileStore] synchronize];

        [outlineView reloadData];
        [outlineView selectRow: selectedRow byExtendingSelection: NO];
    }
}

- (void)mouseDownEvent: (NSEvent *)mouseEvent
{
    [LiLog logAsDebug: @"[GroupTableDelegate mouseDownEvent: %@]", mouseEvent];
    theMouseDownEvent = mouseEvent;
}
@end

@implementation GroupTableDelegate (OutlineViewDelegate)
- (id)outlineView: (NSOutlineView *)outlineView
            child: (int)index ofItem:(Group *)item
{
    if (item == nil)
        item = theGroup;

    return [[item childAtIndex: index] retain];
}

- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (Group *)item
{
    if (item == nil)
        item = theGroup;

    return ([item type] == BRANCH);
}

- (int)outlineView: (NSOutlineView *)outlineView
numberOfChildrenOfItem: (Group *)item
{
    if (item == nil)
        item = theGroup;

    return [item numberOfChildren];
}

- (id)outlineView: (NSOutlineView *)outlineView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
           byItem: (Group *)item
{
    if (item == nil)
        item = theGroup;

    if ([[aTableColumn identifier] isEqualToString: @"name"])
        return [[item name] retain];
    return @"nil";
}

- (void)outlineView: (NSOutlineView *)anOutlineView
     setObjectValue: (id)anObject
     forTableColumn: (NSTableColumn *)aTableColumn
             byItem: (id)anItem
{
    NSArray *groupFiles;
    NSDictionary *renamedGroupAttribute;
    NSString *oldGroupName, *newGroupName;
    LiFileHandle *file;
    LiFilter *groupFilter;
    Group *renamedGroup;

    renamedGroup = anItem;
    groupFilter = [LiFilter filterWithAttribute: LiGroupsAttribute
                                compareSelector: @selector(isEqual:)
                                          value: [renamedGroup name]];
    groupFiles = [[renamedGroup fileStore] filesMatchingFilter: groupFilter];
    oldGroupName = [renamedGroup name];
    newGroupName = anObject;
    for (file in groupFiles) {
        [file renameGroup: oldGroupName toGroup: newGroupName];
    }
    [renamedGroup setName: newGroupName];

    renamedGroupAttribute = [NSDictionary dictionaryWithObject: oldGroupName
                                                        forKey: LiGroupsAttribute];
    [[[renamedGroup fileStore] delegate] changeDefaultValueForAttribute: renamedGroupAttribute
                                                                toValue: newGroupName
                                                  inFileStore: [renamedGroup fileStore]];
    
    [[renamedGroup fileStore] synchronize];
    [self setSelectedGroup: renamedGroup];
}

- (BOOL)outlineView: (NSOutlineView *)outlineView
shouldEditTableColumn: (NSTableColumn *)tableColumn
               item: (id)anItem
{
    Group *group;

    group = anItem;
    return [[group fileStore] isEditable];
}

- (void)outlineView: (NSOutlineView *)outlineView
    willDisplayCell: (NSCell *)aCell
     forTableColumn: (NSTableColumn *)aColumn
               item: (id)theItem
{
    if (theItem == nil)
        return;

    if ([[aColumn identifier] isEqualToString: @"name"]) {
        [aCell setImage: [[theItem icon] retain]];
        //[aCell setStringValue: [theItem name]];
    }
}

- (BOOL)outlineView: (NSOutlineView *)anOutlineView
   shouldSelectItem: (id)item
{
    return YES;
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
    Group *group;

    [LiLog logAsDebug: @"[GroupTableDelegate outlineViewSelectionDidChange: (Notification)]"];
    [LiLog indentDebugLog];
    
    group = [outlineView itemAtRow: [outlineView selectedRow]];
    [self setSelectedGroup: group];

    [LiLog unindentDebugLog];
}

- (NSDragOperation)outlineView: (NSOutlineView*)olv
                  validateDrop: (id <NSDraggingInfo>)info
                  proposedItem: (id)anItem
            proposedChildIndex: (int)childIndex
{
    Group *group;
    NSPasteboard *pboard;

    group = anItem;
    if (group == nil)
        return NSDragOperationNone;

    if (childIndex != NSOutlineViewDropOnItemIndex)
        return NSDragOperationNone;

    if ([[group fileStore] isEditable] == NO)
        return NSDragOperationNone;

    pboard = [info draggingPasteboard];
    if ([pboard availableTypeFromArray:
        [NSArray arrayWithObjects:
            LiaisonPboardType, NSFilenamesPboardType, nil]])
        return NSDragOperationCopy;

    return NO;
}

- (BOOL)outlineView: (NSOutlineView*)olv
         acceptDrop: (id <NSDraggingInfo>)info
               item: (id)anItem
         childIndex: (int)childIndex
{
    Group *item;
    NSPasteboard *pboard;
    NSString *groupName;

    item = anItem;
    if ([self groupIsLibrary: item])
        groupName = nil;
    else
        groupName = [item name];

    pboard = [info draggingPasteboard];

    if ([pboard availableTypeFromArray:
        [NSArray arrayWithObject: LiaisonPboardType]]) {
        NSArray *theFileList;
        NSData *theFileListData;
        LiFileHandle *file;

        theFileListData = [pboard dataForType: LiaisonPboardType];
        theFileList = [NSKeyedUnarchiver unarchiveObjectWithData:
            theFileListData];
        for (file in theFileList) {
            [file addToGroup: groupName];
        }
    } else if ([pboard availableTypeFromArray:
        [NSArray arrayWithObject: NSFilenamesPboardType]]) {
        NSArray *pathList;

        pathList = [pboard propertyListForType: NSFilenamesPboardType];
        if ([pathList count] > 0) {
            [[item fileStore] addPaths: pathList toGroup: [item name]];
            return YES;
        } else
            return NO;
    }

    [[item fileStore] synchronize];
    
    return YES;
}

- (BOOL)outlineView: (NSOutlineView *)anOutlineView
         writeItems: (NSArray *)someItems
       toPasteboard: (NSPasteboard *)aPasteboard
{
    Group *item;
    NSMutableArray *promisePboard;

    promisePboard = [NSMutableArray array];
    
    for (item in someItems) {
        [promisePboard addObject: [item name]];
    }

    if ([promisePboard count] > 0) {
        NSPoint dragPosition;
        NSRect imageLocation;

        dragPosition = [outlineView convertPoint: [theMouseDownEvent locationInWindow]
                                        fromView: nil];
        imageLocation.origin = dragPosition;
        imageLocation.size = NSMakeSize(32,32);
        [outlineView dragPromisedFilesOfTypes: [NSArray arrayWithObject: @""]
                                     fromRect: NSMakeRect(0.0, 0.0, 0.0, 0.0)
                                       source: self
                                    slideBack: YES event: theMouseDownEvent];
        return YES;
    }

    // We always return NO, because we start the drag ourselves, which is lame,
    // but we have to in order to support promised files.
    return NO;
}

/* We get this in response to dragging a directory to another app. */
- (NSArray *)namesOfPromisedFilesDroppedAtDestination: (NSURL *)dropDestination
{
    NSArray *filenames;
    NSFileManager *defaultManager;
    NSString *dropDir, *path;
    int suffix;

    defaultManager = [NSFileManager defaultManager];
    dropDir = [dropDestination path];
    for (suffix = 1; suffix <= 100; suffix++) {
        NSString *myDir;
        
        if (suffix > 1)
            myDir = [NSString stringWithFormat: @"DEBUGgroupName %d", suffix];
        else
            myDir = @"DEBUGgroupName";

        path = [dropDir stringByAppendingPathComponent: myDir];
        if ([defaultManager fileExistsAtPath: path] == NO) {
            break;
        }
    }

    filenames = nil;
    if (suffix <= 100) {
        [LiLog logAsDebug: @"Create dir: %@", path];
        if ([defaultManager createDirectoryAtPath: path
                                       attributes: nil] == YES)
            filenames = [NSArray arrayWithObject: path];
    }
    return filenames;
}
@end

@implementation GroupTableDelegate
- (id)init
{
    NSNotificationCenter *defaultCenter;
    
    self = [super init];

    [self setGroup: nil];

    // We want to watch for file changes, so we can change our view.
    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(respondToFileStoreChanged:)
                          name: LiFileStoresChangedNotification
                        object: nil];
    [defaultCenter addObserver: self
                      selector: @selector(respondToFileStoreChanged:)
                          name: LiFileChangedNotification
                        object: nil];
    
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *defaultCenter;

    defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver: self];
    
    [self setGroup: nil];
    [super dealloc];
}

- (void)awakeFromNib
{
    NSTableColumn *tableColumn;
    ImageAndTextCell *imageAndTextCell;

    tableColumn = [outlineView tableColumnWithIdentifier: @"name"];
    imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: YES];
    [tableColumn setDataCell: imageAndTextCell];

    [outlineView registerForDraggedTypes:
        [NSArray arrayWithObjects:
            LiaisonPboardType, NSFilenamesPboardType, nil]];
}

- (void)respondToFileStoreChanged: (NSNotification *)aNotification
{
    Group *myGroups, *child;
    LiFileStore *fileStore;
    NSEnumerator *fsEnum, *groupEnum;
    NSMutableSet *oldFileStores, *newFileStores;
    NSString *groupName;
    BOOL needsRedisplay;

    myGroups = [self group];
    if (myGroups == nil) {
        myGroups = [Group groupWithName: @"ALL" andType: BRANCH];
        [self setGroup: myGroups];
    }
    needsRedisplay = NO;
    
    newFileStores = [NSMutableSet setWithArray: [LiFileStore allFileStores]];
    oldFileStores = [NSMutableSet set];
    groupEnum = [myGroups childEnumerator];
    while ((child = [groupEnum nextObject]) != nil) {
        [oldFileStores addObject: [child fileStore]];
    }
    
    // Remove old file stores.
    [oldFileStores minusSet: newFileStores];
    if ([oldFileStores count] > 0)
        needsRedisplay = YES;
    
    groupEnum = [oldFileStores objectEnumerator];
    while ((groupName = [[groupEnum nextObject] name]) != nil) {
        [LiLog logAsDebug: @"Removing fileStore for %@ from the group list.", groupName];
        [myGroups removeChildNamed: groupName];
    }
    
    fsEnum = [LiFileStore fileStoreEnumerator];
    while ((fileStore = [fsEnum nextObject]) != nil) {
        Group *storeGroup;
        NSArray *allStoreGroups;
        NSEnumerator *groupEnum;

        allStoreGroups = [fileStore allValuesForAttribute: LiGroupsAttribute];
        storeGroup = [myGroups childNamed: [fileStore name]];
        if (storeGroup == nil) {
            needsRedisplay = YES;
            storeGroup = [Group groupWithName: [fileStore name] andType: BRANCH];

            [myGroups addChild: storeGroup];
        } else {
            NSMutableSet *oldGroups, *newGroups;
            
            newGroups = [NSMutableSet setWithArray: allStoreGroups];
            oldGroups = [NSMutableSet set];
            groupEnum = [storeGroup childEnumerator];
            while ((child = [groupEnum nextObject]) != nil) {
                [oldGroups addObject: [child name]];
            }
            
            // Remove old groups.
            [oldGroups minusSet: newGroups];
            if ([oldGroups count] > 0)
                needsRedisplay = YES;
            
            for (groupName in oldGroups) {
                [LiLog logAsDebug: @"Removing group %@ from group list.", groupName];
                [storeGroup removeChildNamed: groupName];
            }
        }

        // Always set this.
        [storeGroup setIcon: [fileStore icon]];
        [storeGroup setFileStore: fileStore];
        
        // Add new groups.
        for (groupName in allStoreGroups) {
            Group *subGroup;
            
            if ([storeGroup childNamed: groupName] == nil) {
                needsRedisplay = YES;
                subGroup = [Group groupWithName: groupName andType: LEAF];
                [subGroup setFileStore: fileStore];
                [storeGroup addChild: subGroup];
            }
        }        
    }

    if (needsRedisplay) {
        [outlineView reloadData];
    }
}

- (void)highlightDefaultGroup
{
    Group *firstGroup;

    firstGroup = [outlineView itemAtRow: 0];
    [outlineView selectRow: 0 byExtendingSelection: NO];
}

- (IBAction)addGroup:(id)sender
{
    Group *group;
    NSString *untitledName;
    unsigned long untitledPrefix;
    
    [LiLog logAsDebug: @"[GroupTableDelegate addGroup: sender]"];
    [LiLog indentDebugLog];

    group = [self selectedGroup];
    if ([[group fileStore] isEditable] == NO) {
        [LiLog logAsDebug: @"Group %@ isn't editable.", [[group fileStore] name]];
    }

    if ([[group fileStore] isEditable]) {
        Group *newGroup;
        NSDictionary *newGroupAttribute;
        
        if ([group type] == LEAF)
            group = [group parent];
        [LiLog logAsDebug: @"adding to group: %@", [group name]];
        
        untitledPrefix = 1;
        untitledName = myLocalizedString(@"LiUntitledGroupName");
        while ([group childNamed: untitledName] != nil) {
            untitledPrefix++;
            untitledName = [NSString stringWithFormat: @"%@ %lu",
                myLocalizedString(@"LiUntitledGroupName"), untitledPrefix];
        }

        newGroupAttribute = [NSDictionary dictionaryWithObject: untitledName
                                                        forKey: LiGroupsAttribute];
        [[[group fileStore] delegate] addDefaultAttribute: newGroupAttribute
                                              toFileStore: [group fileStore]];
        
        newGroup = [Group groupWithName: untitledName andType: LEAF];
        [newGroup setFileStore: [group fileStore]];
        [group addChild: newGroup];
        
        [outlineView reloadData];
        [outlineView expandItem: group];
    }

    [LiLog unindentDebugLog];
}

- (NSSize)minSize
{
    float rowHeight;
    int numRows;
    
    [LiLog logAsDebug: @"[GroupTableDelegate minSize]"];
    rowHeight =  [outlineView rowHeight];
    numRows = [outlineView numberOfRows];
    return NSMakeSize([outlineView frame].size.width, rowHeight * numRows);
}

- (BOOL)validateAction: (SEL)anAction
{
    //[LiLog logAsDebug: @"[GroupTableDelegate validateAction: %@]", NSStringFromSelector(anAction)];
    if (anAction == @selector(copy:))
        return [outlineView numberOfSelectedRows] > 0;
    else if (anAction == @selector(delete:)) {
        if ([self groupIsLibrary: [self selectedGroup]])
            return NO;
        else
            return [[[self selectedGroup] fileStore] isEditable];
    } else if (anAction == @selector(addGroup:)) {
        return [[[self selectedGroup] fileStore] isEditable];
    } else
        return YES;
}

- (BOOL)validateMenuItem: (NSMenuItem *)anItem
{
    return [self validateAction: [anItem action]];
}
@synthesize theGroup;
@synthesize theMouseDownEvent;
@synthesize theWindow;
@synthesize theFileDelegate;
@synthesize theSelectedGroup;
@synthesize theContextMenu;
@synthesize statusLine;
@synthesize outlineView;
@end

@implementation GroupTableDelegate (Accessors)
- (Group *)group
{
    return theGroup;
}

- (void)setGroup: (Group *)aGroup
{
    [aGroup retain];
    [theGroup release];
    theGroup = aGroup;

    [outlineView reloadData];
    [self highlightDefaultGroup];
}

- (Group *)selectedGroup
{
    return theSelectedGroup;
}

- (void)setSelectedGroup: (Group *)aGroup
{
    [aGroup retain];
    [theSelectedGroup release];
    theSelectedGroup = aGroup;

    [theFileDelegate saveSelectionOfTableView: [theFileDelegate tableView]];

    [theFileDelegate setFileStore: [theSelectedGroup fileStore]];

    if ([self groupIsLibrary: theSelectedGroup]) {
        [theFileDelegate setGroup: nil];
    } else {
        [theFileDelegate setGroup: [theSelectedGroup name]];
    }
    [theFileDelegate redisplay];
    [theFileDelegate restoreSelectionToTableView: [theFileDelegate tableView] refresh: YES];
}
@end

@implementation GroupTableDelegate (Private)
- (BOOL)groupIsLibrary: (Group *)aGroup
{
    if ([[self group] hasChild: aGroup])
        return YES;
    else
        return NO;
}
@end
