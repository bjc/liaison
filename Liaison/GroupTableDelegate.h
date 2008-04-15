/* GroupTableDelegate */

@class Group;
@class FileTableDelegate;
@class WindowController;

@interface GroupTableDelegate : NSObject
{
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *statusLine;
    IBOutlet WindowController *theWindow;
    IBOutlet FileTableDelegate *theFileDelegate;
    IBOutlet NSMenu *theContextMenu;

    Group *theGroup;
    Group *theSelectedGroup;

    NSEvent *theMouseDownEvent;
}
- (IBAction)addGroup:(id)sender;

- (NSSize)minSize;
- (void)respondToFileStoreChanged: (NSNotification *)aNotification;

- (BOOL)validateAction: (SEL)anAction;

- (void)highlightDefaultGroup;
@property (retain,getter=group) Group *theGroup;
@property (retain) NSEvent *theMouseDownEvent;
@property (retain) NSTextField *statusLine;
@property (retain) FileTableDelegate *theFileDelegate;
@property (retain) NSMenu *theContextMenu;
@property (retain,getter=selectedGroup) Group *theSelectedGroup;
@property (retain) NSOutlineView *outlineView;
@property (retain) WindowController *theWindow;
@end

@interface GroupTableDelegate (Accessors)
- (Group *)group;
- (void)setGroup: (Group *)aGroup;
- (Group *)selectedGroup;
- (void)setSelectedGroup: (Group *)aGroup;
@end