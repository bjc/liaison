#import "InspectorController.h"

#import "PluginManager.h"

@implementation InspectorController (WindowDelegate)
- (NSRect)windowWillUseStandardFrame: (NSWindow *)aWindow
                        defaultFrame: (NSRect)defaultFrame
{
    return [self minWindowFrame];
}
@end

@implementation InspectorController
- (id)init
{
    self = [super init];
    
    theInspectorViews = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    [theInspectorViews release];
    [super dealloc];
}

- (LiInspectorView *)viewForDefault
{
    LiInspectorView *view;

    view = [[[LiInspectorView alloc] init] autorelease];
    [view setIdentifier: @"nothing"];
    [view setName: @"Nada"];
    [view setImage: nil];
    [view setIsHorizontallyResizable: NO];
    [view setIsVerticallyResizable: NO];
    [view setView: theDefaultTabView];
    [view setViewSize: [[view view] frame].size];

    return view;
}

- (void)awakeFromNib
{
    NSEnumerator *pluginEnum;
    NSObject <LiInspectorPlugin> *plugin;
    
    [self setFile: nil];

    // Load our default, "nothing's there" view.
    [theInspectorViews setObject: [self viewForDefault] forKey: @"DEFAULT"];
    
    // Load plug-in views.
    pluginEnum = [[[PluginManager defaultManager] inspectorPlugins] objectEnumerator];
    while ((plugin = [pluginEnum nextObject]) != nil) {
        LiInspectorView *view;
        NSEnumerator *viewEnum;

        viewEnum = [[plugin allInspectorViews] objectEnumerator];
        while ((view = [viewEnum nextObject]) != nil) {
            NSString *identifier;

            identifier = [NSString stringWithFormat: @"%@:%@",
                NSStringFromClass([plugin class]), [view identifier]];
            [theInspectorViews setObject: view forKey: identifier];
        }
    }
}

- (LiInspectorView *)inspectorViewForIdentifier: (NSString *)anIdentifier
{
    return [theInspectorViews objectForKey: anIdentifier];
}

- (void)showInspectorViewWithIdentifier: (NSString *)anIdentifier
{
    LiInspectorView *view;

    view = [self inspectorViewForIdentifier: anIdentifier];
    if (view != nil) {
        NSTabViewItem *tab;

        tab = [[NSTabViewItem alloc] initWithIdentifier: anIdentifier];
        [tab autorelease];
        [tab setLabel: [view name]];
        [tab setView: [view view]];
        [theTabView addTabViewItem: tab];
    }
}

- (void)removeInspectorViewWithIdentifier: (NSString *)anIdentifier
{
    LiInspectorView *view;

    view = [self inspectorViewForIdentifier: anIdentifier];
}

- (NSRect)minWindowFrame
{
    LiInspectorView *inspectorView;
    NSTabViewItem *tab;
    NSRect windowFrame;
    NSSize viewSize;
    float newHeight, newWidth;

    tab = [theTabView selectedTabViewItem];
    inspectorView = [self inspectorViewForIdentifier: [tab identifier]];

    viewSize = [inspectorView viewSize];
    newHeight = viewSize.height + 40;
    newWidth = viewSize.width;

    windowFrame = [NSWindow contentRectForFrameRect: [theWindow frame]
                                          styleMask: [theWindow styleMask]];
    windowFrame.origin.y += windowFrame.size.height;
    windowFrame.origin.y -= newHeight;
    windowFrame.size.height = newHeight;
    windowFrame.size.width = newWidth;

    windowFrame = [NSWindow frameRectForContentRect: windowFrame
                                          styleMask: [theWindow styleMask]];

    return windowFrame;
}

- (void)resizeWindow
{
    LiInspectorView *inspectorView;
    NSTabViewItem *tab;
    NSRect minWindowFrame, windowFrame;
    BOOL displayGrowBox = NO;

    tab = [theTabView selectedTabViewItem];
    inspectorView = [self inspectorViewForIdentifier: [tab identifier]];

    windowFrame = [theWindow frame];
    minWindowFrame = [self minWindowFrame];
    if ([inspectorView isVerticallyResizable] &&
        [inspectorView isHorizontallyResizable]) {
        // Resize nothing.
        if (windowFrame.size.width < minWindowFrame.size.width)
            windowFrame.size.width = minWindowFrame.size.width;
        if (windowFrame.size.height < minWindowFrame.size.height)
            windowFrame.size.height = minWindowFrame.size.height;
        
        displayGrowBox = YES;
    } else {
        if ([inspectorView isVerticallyResizable]) {
            // Resize the width.
            windowFrame.size.width = minWindowFrame.size.width;
            if (windowFrame.size.height < minWindowFrame.size.height)
                windowFrame.size.height = minWindowFrame.size.height;
            
            displayGrowBox = YES;
        } else if ([inspectorView isHorizontallyResizable]) {
            // Resize the height.
            windowFrame.origin.y = minWindowFrame.origin.y;
            windowFrame.size.height = minWindowFrame.size.height;
            if (windowFrame.size.width < minWindowFrame.size.width)
                windowFrame.size.width = minWindowFrame.size.width;
            
            displayGrowBox = YES;
        } else
            windowFrame = minWindowFrame;
    }
    [theWindow setFrame: windowFrame display: YES animate: YES];
    [theWindow setShowsResizeIndicator: displayGrowBox];
}

- (void)setFile: (LiFileHandle *)aFile
{
    NSEnumerator *pluginEnum, *tabEnum;
    NSMutableArray *shownTabs;
    NSString *identifier;
    NSTabViewItem *tab;
    NSObject <LiInspectorPlugin> *plugin;

    shownTabs = [NSMutableArray array];
    pluginEnum = [[[PluginManager defaultManager] inspectorPlugins] objectEnumerator];
    while ((plugin = [pluginEnum nextObject]) != nil) {
        LiInspectorView *view;
        NSEnumerator *viewEnum;

        viewEnum = [[plugin inspectorViewsForFile: aFile] objectEnumerator];
        while ((view = [viewEnum nextObject]) != nil) {
            identifier = [NSString stringWithFormat: @"%@:%@",
                NSStringFromClass([plugin class]), [view identifier]];
            [shownTabs addObject: identifier];
        }

        NS_DURING
            [plugin setFile: aFile];
        NS_HANDLER
            [LiLog logAsError:
           @"Inspector plugin: %@ couldn't handle '%@': %@, %@",
                NSStringFromClass([plugin class]),
                [aFile filename], [localException name],
                [localException reason]];
        NS_ENDHANDLER
    }

    tabEnum = [[theTabView tabViewItems] objectEnumerator];
    while ((tab = [tabEnum nextObject]) != nil) {
        if ([shownTabs containsObject: [tab identifier]])
            [shownTabs removeObject: [tab identifier]];
        else
            [theTabView removeTabViewItem: tab];
    }

    for (identifier in shownTabs) {
        [self showInspectorViewWithIdentifier: identifier];
    }

    if ([theTabView numberOfTabViewItems] == 0) {
        [LiLog logAsDebug: @"No tabs in view."];

        [self showInspectorViewWithIdentifier: @"DEFAULT"];
    }
}
@synthesize theWindow;
@synthesize theInspectorViews;
@synthesize theTabView;
@synthesize theDefaultTabView;
@synthesize theFile;
@end

@implementation InspectorController (TabViewDelegate)
- (void)tabView: (NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
    LiInspectorView *inspectorView;
    NSTabViewItem *tab;
    NSSize minSize, maxSize;

    tab = [theTabView selectedTabViewItem];
    inspectorView = [self inspectorViewForIdentifier: [tab identifier]];

    minSize = [self minWindowFrame].size;
    maxSize = NSMakeSize(800.0, 800.0);
    if ([inspectorView isHorizontallyResizable] == NO)
        maxSize.width = minSize.width;
    if ([inspectorView isVerticallyResizable] == NO)
        maxSize.height = minSize.height;

    [theWindow setMinSize: minSize];
    [theWindow setMaxSize: maxSize];
    [self resizeWindow];
}
@end