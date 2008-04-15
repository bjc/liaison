#import "ViewOptionsController.h"

#import "FileTableDelegate.h"

@implementation ViewOptionsController
- (id)init
{
    self = [super init];

    theShownColumns = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc
{
    [theShownColumns release];
    [super dealloc];
}

- (void)toggledButton: (id)sender
{
    NSButtonCell *senderCell;
    NSMutableArray *colOrder;
    NSMutableDictionary *listPrefs;
    NSString *colID;

    senderCell = [sender selectedCell];
    listPrefs = [theFileDelegate listPrefs];
    colOrder = [listPrefs objectForKey: @"columnOrder"];
    colID = [theShownColumns objectAtIndex: [senderCell tag]];
    if (colID != nil) {
        if ([senderCell state] == 1) {
            [theFileDelegate showColumnWithIdentifier: colID];
            [colOrder addObject: colID];
        } else {
            [theFileDelegate removeColumnWithIdentifier: colID];
            [colOrder removeObject: colID];
        }
    }

    [theFileDelegate setListPrefs: listPrefs];
}

- (void)sizeWindowToFit
{
    NSRect contentRect, headerRect, windowFrame, oldWindowFrame;

    oldWindowFrame = [NSWindow contentRectForFrameRect: [theWindow frame]
                                             styleMask: [theWindow styleMask]];

    [layoutMatrix sizeToCells];
    contentRect = [theContentView frame];
    contentRect.size = [layoutMatrix bounds].size;
    headerRect = [theHeaderField frame];
    
    windowFrame.origin = oldWindowFrame.origin;
    windowFrame.size.width = MAX(2*contentRect.origin.x + contentRect.size.width,
                                 headerRect.origin.x + headerRect.size.width + 20);
    windowFrame.size.height = headerRect.size.height + contentRect.size.height;
    windowFrame = [NSWindow frameRectForContentRect: windowFrame
                                          styleMask: [theWindow styleMask]];
    [theWindow setFrame: windowFrame display: YES animate: NO];

    [theHeaderField setFrameOrigin:
        NSMakePoint(headerRect.origin.x, contentRect.size.height)];
    [theContentView setFrame: contentRect];
}

- (IBAction)showWindow: (id)sender
{
    NSDictionary *browserColumns;
    NSEnumerator *columnEnum;
    NSMutableArray *optionCol;
    NSString *identifier;
    NSRect tmpRect;
    unsigned int numRows;
    int cellTag;

    layoutMatrix = [[NSMatrix alloc] initWithFrame: NSMakeRect(0.0, 0.0, 0.0, 0.0)];
    [layoutMatrix autorelease];
    [layoutMatrix setMode: NSTrackModeMatrix];
    [layoutMatrix setCellSize: NSMakeSize(100.0, 20.0)];
    [layoutMatrix setDrawsBackground: YES];

    cellTag = 0;
    browserColumns = [theFileDelegate browserColumns];
    numRows = ceil(sqrt([browserColumns count]));
    optionCol = [NSMutableArray array];
    columnEnum = [browserColumns keyEnumerator];
    while ((identifier = [columnEnum nextObject]) != nil) {
        LiBrowserColumn *col;

        col = [theFileDelegate columnForIdentifier: identifier];
        if (col != nil) {
            NSButtonCell *checkBox;
            NSTableColumn *tableCol;
            BOOL checked;

            tableCol = [[theFileDelegate tableView] tableColumnWithIdentifier: identifier];
            if (tableCol == nil)
                checked = 0;
            else
                checked = 1;

            checkBox = [[[NSButtonCell alloc] init] autorelease];
            [checkBox setButtonType: NSSwitchButton];
            [checkBox setTitle: [col name]];
            [checkBox setTag: cellTag];
            [checkBox setTarget: self];
            [checkBox setAction: @selector(toggledButton:)];
            [checkBox setState: checked];

            [theShownColumns addObject: identifier];

            [optionCol addObject: checkBox];
            if ([optionCol count] == numRows) {
                if ([layoutMatrix numberOfColumns] == 0) {
                    unsigned int j;

                    [layoutMatrix addColumn];
                    for (j = [layoutMatrix numberOfRows]; j < numRows; j++) {
                        [layoutMatrix addRowWithCells:
                            [NSArray arrayWithObject: [optionCol objectAtIndex: j]]];
                    }
                    [layoutMatrix putCell: [optionCol objectAtIndex: 0]
                                    atRow: 0 column: 0];
                } else {
                    [layoutMatrix addColumnWithCells: optionCol];
                }
                [optionCol removeAllObjects];
            }
        }

        cellTag++;
    }

    if ([optionCol count] > 0) {
        while ([optionCol count] < numRows)
            [optionCol addObject: [[[NSCell alloc] init] autorelease]];

        [layoutMatrix addColumnWithCells: optionCol];
    }

    tmpRect = [layoutMatrix bounds];
    [theContentView setFrameSize: tmpRect.size];
    [theContentView addSubview: layoutMatrix];
    [self sizeWindowToFit];

    [theWindow makeKeyAndOrderFront: self];
}
@synthesize theShownColumns;
@synthesize theFileDelegate;
@synthesize theWindow;
@synthesize theContentView;
@synthesize theHeaderField;
@synthesize layoutMatrix;
@end
