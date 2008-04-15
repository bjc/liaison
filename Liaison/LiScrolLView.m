//
//  LiScrolLView.m
//  Liaison
//
//  Created by Brian Cully on Sat May 10 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

#import "LiScrolLView.h"

@implementation LiScrollView
- (void)validateScrollers;
{
    BOOL horizVisible, vertVisible;
    NSSize mySize, contentSize;

    mySize = [self frame].size;
    contentSize = [[self documentView] frame].size;

    vertVisible = mySize.height < contentSize.height;
    horizVisible = mySize.width < contentSize.width;

    [self setHasVerticalScroller: vertVisible];
    [self setHasHorizontalScroller: horizVisible];
    
    return;
}

- (void)drawRect: (NSRect)aRect
{
    [self validateScrollers];
    [super drawRect: aRect];
}
@end
