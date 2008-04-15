/* FileTableDelegate */

@class InspectorController;

@interface LiFileStore (BatchPathAdditions)
- (NSArray *)addPaths: (NSArray *)aPathList toGroup: (NSString *)aGroup;
@end

@interface FileTableDelegate : NSObject
{
    IBOutlet InspectorController *inspectorController;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *statusLine;
    IBOutlet NSMenu *theContextMenu;

    NSImage *ascendingSortingImage, *descendingSortingImage;

    LiFileStore *theFileStore;
    LiFilter *theFilter;
    NSString *theSearchString;
    NSTableColumn *theSelectedColumn;
    BOOL isAscending;

    NSArray *theActiveList, *theSortedList;
    NSMutableDictionary *theListPrefs;
    NSMutableDictionary *theTableColumns;
    NSMutableDictionary *theShownColumns;
    NSMutableSet *theSavedSelection;
}
- (IBAction)addFiles: (id)sender;
- (IBAction)openSelectedFiles: (id)sender;
- (IBAction)revealInFinder: (id)sender;

- (NSDictionary *)browserColumns;

- (LiBrowserColumn *)columnForIdentifier: (NSString *)anIdentifier;
- (void)showColumnWithIdentifier: (NSString *)anIdentifier;
- (void)removeColumnWithIdentifier: (NSString *)anIdentifier;
- (int)numberOfFiles;
- (LiFileHandle *)fileAtIndex: (int)index;

- (void)addAttributeFilter: (LiFilter *)aFilter;
- (void)removeAttributeFilter: (LiFilter *)aFilter;

- (void)saveSelectionOfTableView: (NSTableView *)aTableView;
- (void)restoreSelectionToTableView: (NSTableView *)aTableView
                            refresh: (BOOL)inRefresh;

- (NSSize)minSize;

- (BOOL)validateAction: (SEL)anAction;

- (void)redisplay;
@property (retain,getter=shownColumns) NSMutableDictionary *theShownColumns;
@property (retain,getter=searchString) NSString *theSearchString;
@property (retain) InspectorController *inspectorController;
@property (retain,getter=selectedColumn) NSTableColumn *theSelectedColumn;
@property (retain,getter=savedSelection) NSMutableSet *theSavedSelection;
@property (retain) NSMutableDictionary *theTableColumns;
@property (retain,getter=filter) LiFilter *theFilter;
@property (retain) NSTextField *statusLine;
@property (retain) NSMenu *theContextMenu;
@property BOOL isAscending;
@property (retain,getter=tableView) NSTableView *tableView;
@property (retain) NSMutableDictionary *theListPrefs;
@property (retain,getter=fileStore) LiFileStore *theFileStore;
@end

@interface FileTableDelegate (LiTableViewDelegate)
- (void)deleteSelectedRowsInTableView: (NSTableView *)aTableView;
@end

@interface FileTableDelegate (CommonAccessors)
- (NSString *)group;
- (void)setGroup: (NSString *)aGroupName;
@end

@interface FileTableDelegate (Accessors)
- (LiFileStore *)fileStore;
- (void)setFileStore: (LiFileStore *)aFileStore;
- (LiFilter *)filter;
- (void)setFilter: (LiFilter *)aFilter;

- (NSMutableDictionary *)shownColumns;
- (void)setShownColumns: (NSMutableDictionary *)someColumns;

- (NSArray *)sortedList;
- (void)setSortedList: (NSArray *)aFileList;
- (NSArray *)activeList;
- (void)setActiveList: (NSArray *)aFileList;
- (NSArray *)fileList;
- (NSString *)searchString;
- (void)setSearchString: (NSString *)aSearchString;
- (NSTableColumn *)selectedColumn;
- (void)setSelectedColumn: (NSTableColumn *)aColumn;
- (void)setSelectedColumn: (NSTableColumn *)aColumn
              withContext: (void *)someContext;
- (NSMutableSet *)savedSelection;
- (void)setSavedSelection: (NSMutableSet *)aSelection;
- (NSMutableDictionary *)listPrefs;
- (void)setListPrefs: (NSMutableDictionary *)listPrefs;
- (NSMutableDictionary *)columnPrefsForIdentifier: (NSString *)anIdentifier;
- (void)setColumnPrefs: (NSMutableDictionary *)columnPrefs
         forIdentifier: (NSString *)anIdentifier;
- (NSTableView *)tableView;
@end
