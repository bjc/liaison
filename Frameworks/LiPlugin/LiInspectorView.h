//
//  LiInspectorView.h
//  Liaison
//
//  Created by Brian Cully on Wed May 21 2003.
//  Copyright (c) 2003 Brian Cully. All rights reserved.
//

@interface LiInspectorView : NSObject
{
    id theIdentifier;

    NSString *theName;
    NSImage *theImage;
    NSView *theView;
    BOOL theViewIsHorizontallyResizable, theViewisVerticallyResizable;
    NSSize theViewSize;
}
@property (retain,getter=image) NSImage *theImage;
@property (retain,getter=view) NSView *theView;
@property (retain,getter=identifier) id theIdentifier;
@property (retain,getter=name) NSString *theName;
@end

@interface LiInspectorView (Accessors)
- (id)identifier;
- (void)setIdentifier: (id)anIdentifier;
- (NSString *)name;
- (void)setName: (NSString *)aName;
- (NSImage *)image;
- (void)setImage: (NSImage *)anImage;
- (NSView *)view;
- (void)setView: (NSView *)aView;
- (BOOL)isHorizontallyResizable;
- (void)setIsHorizontallyResizable: (BOOL)resizable;
- (BOOL)isVerticallyResizable;
- (void)setIsVerticallyResizable: (BOOL)resizable;
- (NSSize)viewSize;
- (void)setViewSize: (NSSize)aSize;
@end
