//
//  LiBuiltInFunctions.m
//  Liaison
//
//  Created by Brian Cully on Tue May 13 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiBuiltInFunctions.h"

#import "FileSizeFormatter.h"
#import "InspectorViewController.h"
#import "NaturalDateFormatter.h"

#import "IconFamily.h"

static NSString *
myLocalizedString(NSString *aString)
{
    return NSLocalizedStringFromTableInBundle(aString, @"BuiltInFunctions",
                                              [LiBuiltInFunctions bundle], @"");
}

static NSString *
myLocalizedErrorString(NSString *aString)
{
    return NSLocalizedStringFromTableInBundle(aString, @"ErrorMessages",
                                              [LiBuiltInFunctions bundle], @"");
}

@implementation LiBuiltInFunctions
static NSBundle *theBundle = nil;

+ (NSBundle *)bundle
{
    return theBundle;
}

+ (void)setBundle: (NSBundle *)aBundle
{
    [aBundle retain];
    [theBundle release];
    theBundle = aBundle;
}

- (void)convertGroupDict: (NSDictionary *)someGroups
{
    NSArray *groupNames;
    NSMutableDictionary *defaultGroups;
    NSMutableSet *myGroups;
    NSString *libraryName;
    
    libraryName = [someGroups objectForKey: @"name"];
    groupNames = [someGroups objectForKey: @"children"];
    
    myGroups = [NSMutableSet setWithArray: groupNames];
    
    if (libraryName != nil)
        [[self fileStore] setName: libraryName];
    
    defaultGroups = [NSMutableDictionary dictionaryWithObject: myGroups forKey: LiGroupsAttribute];
    [self setDefaultAttributes: defaultGroups];
}

- (void)loadDefaultAttrs
{
    NSDictionary *defaultAttrDict;
    
    defaultAttrDict = [NSDictionary dictionaryWithContentsOfFile: [[Preferences sharedPreferences] groupPath]];
    if (defaultAttrDict != nil) {
        NSNumber *versionNumber;
        
        versionNumber = [defaultAttrDict objectForKey: @"LiDBVersion"];
        if ([versionNumber intValue] == 1) {
            NSDictionary *flattenedDefaults;
            NSEnumerator *defaultEnum;
            NSMutableDictionary *myDefaults;
            NSString *attr;
            
            [LiLog logAsDebug: @"Load my version group dict"];
            myDefaults = [NSMutableDictionary dictionary];
            flattenedDefaults = [defaultAttrDict objectForKey: @"LiDefaultAttributes"];
            defaultEnum = [flattenedDefaults keyEnumerator];
            while ((attr = [defaultEnum nextObject]) != nil) {
                NSMutableSet *values;

                values = [NSMutableSet setWithArray: [flattenedDefaults objectForKey: attr]];
                [myDefaults setObject: values forKey: attr];
            }
            [self setDefaultAttributes: myDefaults];
        } else {
            [self convertGroupDict: defaultAttrDict];
        }
    }
}

- (BOOL)synchronizeDefaultAttrs
{
    NSDictionary *defaultDict;
    NSEnumerator *defaultEnum;
    NSMutableDictionary *flattenedDefaults;
    NSString *attr;
    
    flattenedDefaults = [NSMutableDictionary dictionary];
    defaultEnum = [[self defaultAttributes] keyEnumerator];
    while ((attr = [defaultEnum nextObject]) != nil) {
        NSArray *values;
        
        values = [[[self defaultAttributes] objectForKey: attr] allObjects];
        [flattenedDefaults setObject: values forKey: attr];
    }
    
    defaultDict = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: [NSNumber numberWithInt: 1], flattenedDefaults, nil]
                                              forKeys:
        [NSArray arrayWithObjects: @"LiDBVersion", @"LiDefaultAttributes", nil]];
    
    return [defaultDict writeToFile: [[Preferences sharedPreferences] groupPath] atomically: YES];
}

- (id)init
{
    NSImage *image;
    NSString *iconPath;
    
    self = [super init];

    [self loadDefaultAttrs];
    
    // Register often-used images.
    iconPath = [[NSBundle bundleForClass: [self class]] pathForResource: @"NotThere" ofType: @"icns"];
    image = [[NSImage alloc] initWithContentsOfFile: iconPath];
    [image setName: @"LiBuiltInFunctions NotThereImage"];

    iconPath = [[NSBundle bundleForClass: [self class]] pathForResource: @"local" ofType: @"tiff"];
    image = [[NSImage alloc] initWithContentsOfFile: iconPath];
    [image setName: @"LiBuiltInFunctions FileStoreIcon"];
    
    return self;
}

- (void)dealloc
{
    NSImage *image;

    [self setDefaultAttributes: nil];
    
    // XXX - should this be done this way?
    image = [NSImage imageNamed: @"LiBuiltInFunctions NotThereImage"];
    [image setName: nil];
    [image release];
    image = [NSImage imageNamed: @"LiBuiltInFunctions FileStoreIcon"];
    [image setName: nil];
    [image release];
    
    [super dealloc];
}

- (LiBrowserColumn *)columnForIcon
{
    LiBrowserColumn *col;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"icon"];
    [col setName: myLocalizedString(@"IconHeader")];
    [col setCell: [[[NSImageCell alloc] init] autorelease]];
    [col setWidth: [NSNumber numberWithFloat: 16.0]];
    [col setEditable: NO];
    [col setResizable: NO];
    [col setShowsHeader: NO];
    [col setGetMethod: @selector(icon)];

    return col;
}

- (LiBrowserColumn *)columnForFilename
{
    LiBrowserColumn *col;
    NSCell *cell;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"filename"];
    [col setName: myLocalizedString(@"FilenameHeader")];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    [cell setEditable: YES];
    [col setCell: cell];
    [col setEditable: YES];
    [col setShowsHeader: YES];
    [col setGetMethod: @selector(filename)];
    [col setSetMethod: @selector(setFilename:)];
    [col setCompareMethod: @selector(caseInsensitiveCompare:)];

    return col;
}

- (LiFilterDescription *)descriptionForFilename
{
    LiFilterDescription *description;
    NSCell *cell;
    NSDictionary *compareOps;

    compareOps = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: @"isEqualToString:",
            @"containsString:", nil]
                                             forKeys:
        [NSArray arrayWithObjects: myLocalizedString(@"LiEqualsOperator"),
            myLocalizedString(@"LiContainsOperator"), nil]];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    [cell setEditable: YES];
    description = [LiFilterDescription descriptionForMethod: @selector(filename)
                                                       name: myLocalizedString(LiFilenameAttribute)
                                           compareOperators: compareOps
                                            valueEditorCell: cell];
    
    return description;
}

- (LiBrowserColumn *)columnForType
{
    LiBrowserColumn *col;
    NSCell *cell;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"type"];
    [col setName: myLocalizedString(@"TypeHeader")];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    [cell setEditable: YES];
    [col setCell: cell];
    [col setEditable: YES];
    [col setShowsHeader: YES];
    [col setGetMethod: @selector(type)];
    [col setSetMethod: @selector(setType:)];
    [col setCompareMethod: @selector(caseInsensitiveCompare:)];

    return col;
}

- (LiBrowserColumn *)columnForLastModified
{
    LiBrowserColumn *col;
    NSCell *cell;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"lastModified"];
    [col setName: myLocalizedString(@"LastModifiedTimeHeader")];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    [cell setFormatter: [[[NaturalDateFormatter alloc] initWithNaturalLanguage: YES] autorelease]];
    [cell setEditable: YES];
    [cell setAlignment: NSRightTextAlignment];
    [col setCell: cell];
    [col setEditable: YES];
    [col setShowsHeader: YES];
    [col setGetMethod: @selector(lastModifiedTime)];
    [col setSetMethod: @selector(setLastModifiedTime:)];
    [col setCompareMethod: @selector(compare:)];

    return col;
}

- (LiBrowserColumn *)columnForCreation
{
    LiBrowserColumn *col;
    NSCell *cell;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"creation"];
    [col setName: myLocalizedString(@"CreatedTimeHeader")];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    [cell setFormatter: [[[NaturalDateFormatter alloc] initWithNaturalLanguage: YES] autorelease]];
    [cell setEditable: YES];
    [cell setAlignment: NSRightTextAlignment];
    [col setCell: cell];
    [col setEditable: YES];
    [col setShowsHeader: YES];
    [col setGetMethod: @selector(creationTime)];
    [col setSetMethod: @selector(setCreationTime:)];
    [col setCompareMethod: @selector(compare:)];

    return col;
}

- (LiBrowserColumn *)columnForSize
{
    LiBrowserColumn *col;
    FileSizeFormatter *cellFormatter;
    NSCell *cell;

    col = [[[LiBrowserColumn alloc] init] autorelease];
    [col setIdentifier: @"size"];
    [col setName: myLocalizedString(@"FileSizeHeader")];
    cell = [[[NSTextFieldCell alloc] init] autorelease];
    cellFormatter = [[[FileSizeFormatter alloc] init] autorelease];
    [cellFormatter setAllowsFloats: NO];
    [cell setFormatter: cellFormatter];
    [cell setAlignment: NSRightTextAlignment];
    [col setCell: cell];
    [col setEditable: NO];
    [col setShowsHeader: YES];
    [col setGetMethod: @selector(fileSize)];
    [col setCompareMethod: @selector(compare:)];

    return col;
}

- (NSArray *)columns
{
    NSArray *columns;

    columns = [NSArray arrayWithObjects:
        [self columnForIcon], [self columnForFilename], [self columnForType],
        [self columnForLastModified], [self columnForCreation],
        [self columnForSize], nil];

    return columns;
}

- (NSDictionary *)filterDescriptions
{
    NSDictionary *descriptions;

    descriptions = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: [self descriptionForFilename], nil]
                                               forKeys:
        [NSArray arrayWithObjects: LiFilenameAttribute, nil]];
    
    return descriptions;
}

- (LiInspectorView *)viewForFile
{
    LiInspectorView *view;

    view = [[[LiInspectorView alloc] init] autorelease];
    [view setIdentifier: @"file"];
    [view setName: @"File"];
    [view setImage: nil];
    [view setView: [[self viewController] fileView]];
    [view setIsVerticallyResizable: NO];
    [view setIsHorizontallyResizable: YES];
    [view setViewSize: [[view view] frame].size];

    return view;
}

- (LiInspectorView *)viewForHFS
{
    LiInspectorView *view;

    view = [[[LiInspectorView alloc] init] autorelease];
    [view setIdentifier: @"hfs"];
    [view setName: @"HFS"];
    [view setImage: nil];
    [view setIsVerticallyResizable: NO];
    [view setIsHorizontallyResizable: NO];
    [view setView: [[self viewController] hfsView]];
    [view setViewSize: [[view view] frame].size];

    return view;
}

- (NSArray *)allInspectorViews
{
    return [NSArray arrayWithObjects: [self viewForFile], [self viewForHFS], nil];
}

- (NSArray *)inspectorViewsForFile: (LiFileHandle *)aFile
{
    if (aFile != nil) {
        NSMutableArray *viewArray;

        viewArray = [NSMutableArray arrayWithObject: [self viewForFile]];
        [viewArray addObject: [self viewForHFS]];
        return viewArray;
    }
    return nil;
}

- (void)setFile: (LiFileHandle *)aFile
{
    if (aFile != nil) {
        [[self viewController] setFile: aFile];
    }
}

//
// File store delegate stuff.
//
- (void)openFileHandle: (LiFileHandle *)aFileHandle
{
    NSString *path;

    path = [aFileHandle path];
    if (path != nil) {
        [[NSWorkspace sharedWorkspace] openFile: [aFileHandle path]];
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL: [NSURL fileURLWithPath: [aFileHandle path]]];
    } else {
        [LiLog alertWithHeader: @"Couldn't locate file" contents: @"This message sucks and will be changed so you can locate the file again."];
    }
}

- (void)copyFile: (LiFileHandle *)aFileHandle
{
    [LiLog logAsDebug: @"should copy %@", [aFileHandle filename]];
}

- (NSDictionary *)fileSystemAttributesForPath: (NSString *)aPath
{
    NSMutableDictionary *tmpAttributes;

    tmpAttributes = nil;
    if (aPath != nil) {
        BDAlias *alias;
        NSString *filename, *filetype, *dir;

        // Set the attributes that are valid for every file with a path.
        tmpAttributes = [NSMutableDictionary dictionary];
        filename = [[aPath lastPathComponent] stringByDeletingPathExtension];
        filetype = [aPath pathExtension];
        dir = [aPath stringByDeletingLastPathComponent];
        [tmpAttributes setObject: filename forKey: LiFilenameAttribute];
        [tmpAttributes setObject: filetype forKey: LiTypeAttribute];
        [tmpAttributes setObject: dir forKey: LiDirectoryAttribute];
        
        // Test if the file is resolvable by getting its alias.
        alias = [BDAlias aliasWithPath: aPath];
        if (alias != nil) {
            NSDate *modifiedTime, *createdTime;
            NSDictionary *fileAttrs;
            NSFileWrapper *file;
            NSNumber *fileSize, *hfsCreator, *hfsType;
            NSString *application;

            [tmpAttributes setObject: [alias aliasData]
                              forKey: LiAliasDataAttribute];

            file = [[NSFileWrapper alloc] initWithPath: aPath];
            fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath: aPath traverseLink: YES];

            // Load attributes from disk.
            modifiedTime = [fileAttrs objectForKey: NSFileModificationDate];
            createdTime = [fileAttrs objectForKey: NSFileCreationDate];
            fileSize = [fileAttrs objectForKey: NSFileSize];
            hfsCreator = [fileAttrs objectForKey: NSFileHFSCreatorCode];
            hfsType = [fileAttrs objectForKey: NSFileHFSTypeCode];
            [[NSWorkspace sharedWorkspace] getInfoForFile: aPath
                                              application: &application
                                                     type: &filetype];
            if (modifiedTime != nil)
                [tmpAttributes setObject: modifiedTime
                                  forKey: LiLastModifiedDateAttribute];
            if (createdTime != nil)
                [tmpAttributes setObject: createdTime
                                  forKey: LiCreationDateAttribute];
            if (fileSize != nil)
                [tmpAttributes setObject: fileSize
                                  forKey: LiFileSizeAttribute];
            if (application != nil)
                [tmpAttributes setObject: application
                                  forKey: LiApplicationAttribute];
            if (hfsCreator != nil)
                [tmpAttributes setObject: hfsCreator
                                  forKey: LiHFSCreatorAttribute];
            if (hfsType != nil)
                [tmpAttributes setObject: hfsType
                                  forKey: LiHFSTypeAttribute];
            [tmpAttributes setObject: [NSNumber numberWithBool: YES]
                              forKey: LiIsEditableAttribute];

            [file release];
        } else {
            [tmpAttributes setObject: [NSNumber numberWithBool: NO]
                              forKey: LiIsEditableAttribute];
        }
    }

    return tmpAttributes;
}

- (NSDictionary *)fileSystemAttributesForAliasData: (NSData *)aliasData
{
    BDAlias *alias;

    alias  = [BDAlias aliasWithData: aliasData];
    return [self fileSystemAttributesForPath: [alias fullPath]];
}

- (void)convertFirstVersionDict: (NSDictionary *)fileDict
                      fileStore: (LiFileStore *)aFileStore
{
    NSDictionary *filesInDict, *attrDict;
    NSEnumerator *fileEnum;

    filesInDict = [fileDict objectForKey: @"files"];
    fileEnum = [filesInDict objectEnumerator];
    while ((attrDict = [fileEnum nextObject]) != nil) {
        NSData *fileAlias;
        NSDictionary *fileAttrs;
        NSEnumerator *groupEnum;
        NSMutableArray *fileGroups;
        NSMutableDictionary *myFileAttrs;
        NSNumber *fileHandle;
        NSString *groupname;

        fileHandle = [attrDict objectForKey: @"filehandle"];
        fileAlias = [attrDict objectForKey: @"alias"];

        fileAttrs = [self fileSystemAttributesForAliasData:
            fileAlias];
        if (fileAttrs == nil) {
            [LiLog logAsWarning: @"Couldn't load attributes for %@: abandoning.",
                [attrDict objectForKey: @"path"]];
        }
        myFileAttrs = [NSMutableDictionary dictionaryWithDictionary: fileAttrs];
        [myFileAttrs setObject: fileHandle forKey: LiFileHandleAttribute];

        fileGroups = [NSMutableArray array];
        groupEnum = [[attrDict objectForKey: @"groups"] objectEnumerator];
        while ((groupname = [groupEnum nextObject]) != nil) {
            if ([groupname isEqualToString: @"/"] == NO)
                [fileGroups addObject: groupname];
        }
        [myFileAttrs setObject: fileGroups forKey: LiGroupsAttribute];

        [aFileStore addFileWithAttributes: myFileAttrs];
    }
}

- (BOOL)loadFileStore: (LiFileStore *)aFileStore
{
    NSDictionary *fileStoreDict;

    // Make sure we have the right indexes.
    [aFileStore addIndexForAttribute: LiGroupsAttribute];
    [aFileStore addIndexForAttribute: LiAliasDataAttribute];

    fileStoreDict = [NSDictionary dictionaryWithContentsOfFile: [[Preferences sharedPreferences] libraryPath]];
    if (fileStoreDict != nil) {
        NSNumber *versionNumber;

        versionNumber = [fileStoreDict objectForKey: @"LiDBVersion"];
        if ([versionNumber intValue] == 1) {
            NSArray *allFiles;
            NSDictionary *fileDict;

            allFiles = [fileStoreDict objectForKey: @"LiFileStore"];
            for (fileDict in allFiles) {
                BDAlias *alias;
                NSMutableDictionary *baseAttrs;

                baseAttrs = [[NSMutableDictionary alloc] initWithDictionary: fileDict];

                alias = [[BDAlias alloc] initWithData: [fileDict objectForKey: LiAliasDataAttribute]];
                if ([alias fullPath] == nil) {
                    NSString *path, *filename, *directory;
                    
                    directory = [fileDict objectForKey: LiDirectoryAttribute];
                    filename = [[fileDict objectForKey: LiFilenameAttribute] stringByAppendingPathExtension: [fileDict objectForKey: LiTypeAttribute]];
                    path = [directory stringByAppendingPathComponent: filename];
                    
                    [LiLog logAsDebug: @"Couldn't locate file: %@ - (dir: %@, path: %@)", filename, directory, path];
                    
                    alias = [[BDAlias alloc] initWithPath: path];
                    if ([alias fullPath] != nil) {
                        [baseAttrs setObject: [[alias fullPath] stringByDeletingLastPathComponent] forKey: LiDirectoryAttribute];
                        [baseAttrs setObject: [alias aliasData] forKey: LiAliasDataAttribute];
                    }
                }
                
                if ([alias aliasData] == nil) {
                    [baseAttrs setObject: [NSNumber numberWithBool: NO] forKey: LiIsEditableAttribute];
                } else {
                    [baseAttrs setObject: [NSNumber numberWithBool: YES] forKey: LiIsEditableAttribute];
                }

                [aFileStore addFileWithAttributes: baseAttrs];

                [baseAttrs release];
                [alias release];
            }
        } else {
            [self convertFirstVersionDict: fileStoreDict
                                fileStore: aFileStore];
        }
    }

    [aFileStore synchronize];
    return YES;
}

- (BOOL)synchronizeFileStore
{
    LiFileHandle *fileHandle;
    NSArray *allFileHandles;
    NSMutableArray *allFiles;
    NSDictionary *fileDict;
    NSString *path;

    [LiLog logAsDebug: @"[LiBuiltInFunctions synchronizeFileStore]"];
    [LiLog indentDebugLog];
    
    path = [[Preferences sharedPreferences] libraryPath];

    allFiles = [NSMutableArray array];
    allFileHandles = [[self fileStore] allFileHandles];
    for (fileHandle in allFileHandles) {
        NSMutableDictionary *filteredAttrs;

        filteredAttrs = [NSMutableDictionary dictionaryWithDictionary:
            [fileHandle dictionary]];
        [allFiles addObject: filteredAttrs];
    }

    fileDict = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects:
            [NSNumber numberWithInt: 1], allFiles, nil]
                                           forKeys:
        [NSArray arrayWithObjects:
            @"LiDBVersion", @"LiFileStore", nil]];
    [LiLog logAsDebug: @"writing to: %@", path];
    [fileDict writeToFile: path atomically: YES];
    [LiLog logAsDebug: @"done!"];

    [LiLog unindentDebugLog];
    return YES;
}

- (void)synchronizeFileHandle: (LiFileHandle *)aFileHandle
            withNewAttributes: (NSMutableDictionary *)someAttributes
{
    NSDictionary *fileAttrDict;
    NSEnumerator *attrEnum;
    NSMutableDictionary *fileAttrs;
    NSSet *pathSet;
    NSString *attr;
    BOOL pathDone;

    [LiLog logAsDebug: @"[LiBuiltInFunctions synchronizeFileHandle: (fh) withNewAttributes: %@]", someAttributes];
    [LiLog indentDebugLog];
    
    pathDone = NO;
    pathSet = [NSSet setWithArray:
        [NSArray arrayWithObjects:
            LiDirectoryAttribute, LiFilenameAttribute, LiTypeAttribute, nil]];
    fileAttrDict = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects:
            NSFileModificationDate, NSFileCreationDate,
            NSFileHFSCreatorCode, NSFileHFSTypeCode,
            nil]
                                               forKeys:
        [NSArray arrayWithObjects:
            LiLastModifiedDateAttribute, LiCreationDateAttribute,
            LiHFSCreatorAttribute, LiHFSTypeAttribute,
            nil]];

    fileAttrs = [NSMutableDictionary dictionary];
    attrEnum = [someAttributes keyEnumerator];
    while ((attr = [attrEnum nextObject]) != nil) {
        if (pathDone == NO && [pathSet containsObject: attr]) {
            NSString *filename, *type;
            NSString *path, *oldPath;

            filename = [someAttributes objectForKey: LiFilenameAttribute];
            if (filename == nil)
                filename = [aFileHandle filename];

            type = [someAttributes objectForKey: LiTypeAttribute];
            if (type == nil)
                type = [aFileHandle type];

            path = [someAttributes objectForKey: LiDirectoryAttribute];
            if (path == nil)
                path = [aFileHandle directory];

            if (type && [type length] > 0) {
                filename = [filename stringByAppendingPathExtension: type];
            }
            path = [path stringByAppendingPathComponent: filename];

            oldPath = [[aFileHandle alias] fullPath];
            if ([oldPath isEqualToString: path] == NO) {
                int rc;

                rc = 0;
                rc = rename([oldPath UTF8String], [path UTF8String]);
                if (rc == -1) {
                    NSString *header, *contents;

                    switch (errno) {
                        case ENOENT:
                            header = myLocalizedErrorString(@"LiBadFilenameErrorHeader");
                            contents = myLocalizedErrorString(@"LiBadFilenameErrorContents");
                            break;

                        case EROFS:
                            header = myLocalizedErrorString(@"LiReadOnlyFileSytemErrorHeader");
                            contents = myLocalizedErrorString(@"LiReadOnlyFileSytemErrorContents");
                            break;

                        case EPERM:
                        case EACCES:
                            header = myLocalizedErrorString(@"LiPermissionDeniedErrorHeader");
                            contents = myLocalizedErrorString(@"LiPermissionDeniedErrorContents");
                            break;

                        default:
                            header = myLocalizedErrorString(@"LiGenericRenameErrorHeader");
                            contents = myLocalizedErrorString(@"LiGenericRenameErrorContents");
                    }
                    [LiLog alertWithHeader: header contents: contents];
                }
            }

            pathDone = YES;
        } else if ([fileAttrDict objectForKey: attr] != nil) {
            [fileAttrs setObject: [someAttributes objectForKey: attr]
                          forKey: attr];
        }
    }

    if ([fileAttrs count] > 0) {
        NSFileManager *defaultManager;

        defaultManager = [NSFileManager defaultManager];
        [defaultManager changeFileAttributes: fileAttrs
                                      atPath: [[aFileHandle alias] fullPath]];
    }

    // XXX - should flag to see if the icon needs updating and
    // do it here, since we can't scan for that change.

    [LiLog unindentDebugLog];
}

- (BOOL)shouldUpdateFileHandle: (LiFileHandle *)aFileHandle
{
    NSDate *handleDate, *fileDate;
    NSFileWrapper *file;
    NSString *newPath;

    newPath = [[aFileHandle alias] fullPath];
    if ([newPath compare: [aFileHandle path]] != 0)
        return YES;

    file = [[[NSFileWrapper alloc] initWithPath: newPath] autorelease];
    fileDate = [[file fileAttributes] objectForKey:
        NSFileModificationDate];
    handleDate = [aFileHandle lastModifiedTime];

    if ([fileDate compare: handleDate] == 0)
        return NO;
    else
        return YES;
}

- (void)updateFileHandle: (LiFileHandle *)aFileHandle
{
    NSMutableDictionary *fileAttrs;

    [LiLog logAsDebug: @"[LiBuiltInFunctions updateFileHandle: %@]", [aFileHandle description]];
    fileAttrs = [NSMutableDictionary dictionaryWithDictionary:
        [self fileSystemAttributesForAliasData:
            [aFileHandle valueForAttribute: LiAliasDataAttribute]]];
    [LiLog logAsDebug: @"fileAttrs: %@", [fileAttrs description]];

    // Attempt path resolution if alias resolution fails.
    if ([fileAttrs count] == 0) {
        NSString *filePath, *filename;

        filename = [[aFileHandle filename] stringByAppendingPathExtension: [aFileHandle type]];
        filePath = [[aFileHandle directory] stringByAppendingPathComponent: filename];
        [LiLog logAsDebug: @"Attempting to resolve path %@ to alias", filePath];
        fileAttrs = [NSMutableDictionary dictionaryWithDictionary:
            [self fileSystemAttributesForPath: filePath]];
        [LiLog logAsDebug: @"\tresolved to: %@", fileAttrs];
    }
    
    if (fileAttrs != nil) {
        NSDictionary *myAttrs;
        NSEnumerator *keyEnum;
        NSString *key;

        myAttrs = [[aFileHandle fileStore] attributesForFileHandle:
            aFileHandle];
        keyEnum = [fileAttrs keyEnumerator];
        while ((key = [keyEnum nextObject]) != nil) {
            id myValue;

            myValue = [myAttrs objectForKey: key];
            if (myValue != nil) {
                id value;

                value = [fileAttrs objectForKey: key];
                if (myValue == value) {
                    [fileAttrs removeObjectForKey: key];
                } else {
                    if ([myValue respondsToSelector: @selector(compare:)]) {
                        if ([myValue performSelector: @selector(compare:) withObject: value] == 0) {
                            [fileAttrs removeObjectForKey: key];
                        }
                    } else {
                        // XXX
                        // Disabled because the icon keeps changing
                        // on every check.
                        [fileAttrs removeObjectForKey: key];
                    }
                }
            }
        }

        if ([fileAttrs count] > 0) {
            [LiLog logAsDebug: @"fileAttrs: %@", [fileAttrs description]];
            [[aFileHandle fileStore] updateFileHandle: aFileHandle
                                       withAttributes: fileAttrs];
        }
    }
}

- (LiFileHandle *)addURL: (NSURL *)anURL
             toFileStore: (LiFileStore *)aFileStore
{
    if ([anURL isFileURL] == YES) {
        BDAlias *alias;
        NSArray *existingFiles;
        NSDictionary *fileAttrs;

        // Attempt resolution of the file handle to determine uniqueness.
        // If it's not there, it's automatically unique.
        alias = [BDAlias aliasWithPath: [anURL path]];
        if (alias != nil) {
            LiFilter *filter;

            filter = [LiFilter filterWithAttribute: LiAliasDataAttribute
                                   compareSelector: @selector(isEqual:)
                                             value: [alias aliasData]];
            
            existingFiles = [[self fileStore] filesMatchingFilter: filter];
            if ([existingFiles count] > 0) {
                return [existingFiles objectAtIndex: 0];
            }
        }
        
        fileAttrs = [self fileSystemAttributesForPath: [anURL path]];
        return [[self fileStore] addFileWithAttributes: fileAttrs];
    }
    return nil;
}

- (NSURL *)urlForFileHandle: (LiFileHandle *)aFileHandle
{
    NSString *path;
    NSURL *url;

    url = nil;
    path = [aFileHandle path];
    if (path != nil)
        url = [NSURL fileURLWithPath: path];        
    return url;
}

- (NSArray *)defaultValuesForAttribute: (NSString *)anAttribute
{
    NSMutableSet *values;

    values = [[self defaultAttributes] objectForKey: anAttribute];
    return [values allObjects];
}

- (BOOL)addDefaultAttribute: (NSDictionary *)anAttribute toFileStore: (LiFileStore *)aFileStore
{
    NSEnumerator *attrEnum;
    NSMutableDictionary *defaultAttrs;
    NSMutableSet *values;
    NSString *attr;
    
    [LiLog logAsDebug: @"[LiBuiltInFunctions addDefaultAttribute: %@ toFileStore: %@]", anAttribute, aFileStore];
    [LiLog indentDebugLog];
    defaultAttrs = [self defaultAttributes];
    attrEnum = [anAttribute keyEnumerator];
    while ((attr = [attrEnum nextObject]) != nil) {
        values = [defaultAttrs objectForKey: attr];
        if (values == nil) {
            values = [NSMutableSet set];
            [defaultAttrs setObject: values forKey: attr];
        }
        [values addObject: [anAttribute objectForKey: attr]];
    }

    [LiLog unindentDebugLog];

    return [self synchronizeDefaultAttrs];
}

- (BOOL)changeDefaultValueForAttribute: (NSDictionary *)anAttribute toValue: (id)aValue inFileStore: (LiFileStore *)aFileStore
{
    NSEnumerator *attrEnum;
    NSMutableDictionary *defaultAttrs;
    NSMutableSet *values;
    NSString *attr;
    
    defaultAttrs = [self defaultAttributes];
    attrEnum = [anAttribute keyEnumerator];
    while ((attr = [attrEnum nextObject]) != nil) {
        values = [defaultAttrs objectForKey: attr];
        if (values == nil) {
            return NO;
        }
        [values removeObject: [anAttribute objectForKey: attr]];
        [values addObject: aValue];
    }
    
    return [self synchronizeDefaultAttrs];
}

- (BOOL)removeDefaultAttribute: (NSDictionary *)anAttribute fromFileStore: (LiFileStore *)aFileStore
{
    NSEnumerator *attrEnum;
    NSMutableDictionary *defaultAttrs;
    NSMutableSet *values;
    NSString *attr;
    
    defaultAttrs = [self defaultAttributes];
    attrEnum = [anAttribute keyEnumerator];
    while ((attr = [attrEnum nextObject]) != nil) {
        values = [defaultAttrs objectForKey: attr];
        [values removeObject: [anAttribute objectForKey: attr]];
    }

    return [self synchronizeDefaultAttrs];
}

- (void)initFileStore
{
    LiFileStore *tmpStore;

    tmpStore = [LiFileStore fileStoreWithName: myLocalizedString(@"LiLibraryName")];
    [tmpStore setEditable: YES];
    [tmpStore setIcon: [NSImage imageNamed: @"LiBuiltInFunctions FileStoreIcon"]];
    [tmpStore setDelegate: self];
    [self setFileStore: tmpStore];
    [self loadFileStore: [self fileStore]];
}

- (LiFileStore *)fileStore
{
    return theFileStore;
}
@synthesize theController;
@synthesize theDefaultAttributes;
@synthesize theFileStore;
@end

@implementation LiBuiltInFunctions (Accessors)
- (void)setFileStore: (LiFileStore *)aFileStore
{
    [aFileStore retain];
    [theFileStore release];
    theFileStore = aFileStore;

    [theFileStore setDelegate: self];
}

- (InspectorViewController *)viewController
{
    if (theController == nil) {
        if ([NSBundle loadNibNamed: @"InspectorViews.nib" owner: self] == NO) {
            [LiLog logAsError: @"Couldn't open inspector view nib file."];
            return nil;
        }
    }
    return theController;
}

- (NSMutableDictionary *)defaultAttributes
{
    return theDefaultAttributes;
}

- (void)setDefaultAttributes: (NSMutableDictionary *)someAttributes
{
    [someAttributes retain];
    [theDefaultAttributes release];
    theDefaultAttributes = someAttributes;
}
@end

@implementation LiFileHandle (LiBuiltInFunctions)
- (NSImage *)icon
{
    NSImage *icon;
    NSURL *myURL;

    myURL = [self url];
    if ([myURL isFileURL] == YES)
        icon = [[NSWorkspace sharedWorkspace] iconForFile: [self path]];
    else if (myURL == nil)
        icon = [NSImage imageNamed: @"LiBuiltInFunctions NotThereImage"];
    else
        icon = [[NSWorkspace sharedWorkspace] iconForFileType: [self type]];
    return icon;
}

- (BDAlias *)alias
{
    BDAlias *tmpAlias;

    tmpAlias = [BDAlias aliasWithData:
        [self valueForAttribute: LiAliasDataAttribute]];

    return tmpAlias;
}

- (void)setAlias: (BDAlias *)anAlias
{
    [self setValue: [anAlias aliasData]
      forAttribute: LiAliasDataAttribute];
}

- (NSString *)path
{
    return [[self alias] fullPath];
}

- (NSString *)directory
{
    return [self valueForAttribute: LiDirectoryAttribute];
}
@end