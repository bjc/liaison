//
//  InspectorViewController.m
//  Liaison
//
//  Created by Brian Cully on Wed May 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "InspectorViewController.h"

#import "BDAlias.h"
#import "LiBuiltInFunctions.h"

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTableInBundle(aString, @"BuiltInFunctions",
                                              [LiBuiltInFunctions bundle], @"");
}

@implementation LiFileHandle (LiLocationStuff)
- (NSString *)location
{
    NSData *aliasData;
    NSString *location;

    aliasData = [self valueForAttribute: LiAliasDataAttribute];
    if (aliasData != nil) {
        BDAlias *alias;

        alias = [[BDAlias alloc] initWithData: aliasData];
        if (alias != nil)
            location = [alias fullPath];
        else
            location = myLocalizedString(@"UnableToResolveAlias");
    } else {
        location = [[self url] absoluteString];
    }
    
    return location;
}
@end

@implementation InspectorViewController
- (IBAction)setIcon:(id)sender
{
    [[sender cell] setHighlighted: NO];
}

- (IBAction)setFilename:(id)sender
{
    NSString *filename;

    filename = [theFilenameField stringValue];
    if ([filename compare: [[self file] filename]]) {
        [[self file] setFilename: filename];
    }
}

- (IBAction)setType:(id)sender
{
    NSString *type;

    type = [theTypeField stringValue];
    if ([type compare: [[self file] type]]) {
        [[self file] setType: type];
    }
}

- (IBAction)setApplication:(id)sender
{
    [LiLog logAsDebug: @"[InspectorViewController setApplication:]"];
}

- (IBAction)setHFSTypeField:(id)sender
{
    NSNumber *hfsType;

    hfsType = [hfsTypeField objectValue];
    if ([hfsType compare: [[self file] hfsType]]) {
        [[self file] setHFSType: hfsType];
    }
}

- (IBAction)setHFSCreatorField:(id)sender
{
    NSNumber *hfsCreator;

    hfsCreator = [hfsCreatorField objectValue];
    if ([hfsCreator compare: [[self file] hfsCreator]]) {
        [[self file] setHFSCreator: hfsCreator];
    }
}
@synthesize hfsTypeField;
@synthesize theFileTabView;
@synthesize theTypeField;
@synthesize theHFSTabView;
@synthesize hfsCreatorField;
@synthesize iconView;
@synthesize theApplicationButton;
@synthesize theFilenameField;
@synthesize pathField;
@synthesize theFile;
@end

@implementation InspectorViewController (Accessors)
- (NSView *)fileView
{
    return theFileTabView;
}

- (NSView *)hfsView
{
    return theHFSTabView;
}

- (LiFileHandle *)file
{
    return theFile;
}

- (void)initHFSFields
{
    [hfsCreatorField setObjectValue: [[self file] hfsCreator]];
    [hfsTypeField setObjectValue: [[self file] hfsType]];
}

- (void)setFile: (LiFileHandle *)aFile
{
    NSImage *icon;
    NSMutableArray *applications;
    NSString *filename, *type, *location;
    NSSize iconSize;
    
    [aFile retain];
    [theFile release];
    theFile = aFile;

    icon = [theFile icon];
    iconSize = [iconView bounds].size;
    iconSize.width -= 16.0;
    iconSize.height -= 16.0;
    [icon setSize: iconSize];
    [iconView setImage: icon];

    if ([theFile isEditable]) {
        [theFilenameField setEnabled: YES];
        [theTypeField setEnabled: YES];
        [theApplicationButton setEnabled: YES];
        [iconView setEditable: YES];
        [hfsCreatorField setEditable: YES];
        [hfsTypeField setEditable: YES];
    } else {
        [theFilenameField setEnabled: NO];
        [theTypeField setEnabled: NO];
        [theApplicationButton setEnabled: NO];
        [iconView setEditable: NO];
        [hfsCreatorField setEditable: NO];
        [hfsTypeField setEditable: NO];
    }
    
    filename = [theFile filename];
    if (filename != nil)
        [theFilenameField setStringValue: filename];
    else
        [theFilenameField setStringValue: @""];
    
    type = [theFile type];
    if (type != nil)
        [theTypeField setStringValue: type];
    else
        [theTypeField setStringValue: @""];

    location = [aFile location];
    if (location != nil)
        [pathField setStringValue: location];
    else
        [pathField setStringValue: @"Couldn't locate file."];

    
    applications = [NSMutableArray array];
    if ([theFile application] != nil)
        [applications addObject: [[theFile application] lastPathComponent]];
    
    [theApplicationButton removeAllItems];
    if ([applications count] > 0)
        [theApplicationButton addItemsWithTitles: applications];
    else
        [theApplicationButton addItemWithTitle: @"None"];

    [self initHFSFields];
}
@end
