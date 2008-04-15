//
//  LiInspectorView.m
//  Liaison
//
//  Created by Brian Cully on Wed May 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiInspectorView.h"

@implementation LiInspectorView
@synthesize theImage;
@synthesize theView;
@synthesize theIdentifier;
@synthesize theName;
@end

@implementation LiInspectorView (Accessors)
- (id)identifier
{
    return theIdentifier;
}

- (void)setIdentifier: (id)anIdentifier
{
    [anIdentifier retain];
    [theIdentifier release];
    theIdentifier = anIdentifier;
}

- (NSString *)name
{
    return theName;
}

- (void)setName: (NSString *)aName
{
    [aName retain];
    [theName release];
    theName = aName;
}

- (NSImage *)image
{
    return theImage;
}

- (void)setImage: (NSImage *)anImage
{
    [anImage retain];
    [theImage release];
    theImage = anImage;
}

- (NSView *)view
{
    return theView;
}

- (void)setView: (NSView *)aView
{
    [aView retain];
    [theView release];
    theView = aView;
}

- (BOOL)isHorizontallyResizable
{
    return theViewIsHorizontallyResizable;
}

- (void)setIsHorizontallyResizable: (BOOL)resizable
{
    theViewIsHorizontallyResizable = resizable;
}

- (BOOL)isVerticallyResizable
{
    return theViewisVerticallyResizable;
}

- (void)setIsVerticallyResizable: (BOOL)resizable
{
    theViewisVerticallyResizable = resizable;
}

- (NSSize)viewSize
{
    return theViewSize;
}

- (void)setViewSize: (NSSize)aSize
{
    theViewSize = aSize;
}
@end
