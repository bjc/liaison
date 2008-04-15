/*
 *  Liaison.h
 *  Liaison
 *
 *  Created by Brian Cully on Fri Feb 14 2003.
 *  Copyright (c) 2003 Brian Cully. All rights reserved.
 *
 *  -----
 *
 *  This header file contains common #defines for ipc and other
 *  "configurable" resources.
 */

// We're basically just a front end to this.
#import <LiPlugin/LiPlugin.h>
// That uses this.
#import <Cocoa/Cocoa.h>

// Icons in the browser outline view.
#define LiLocalLibraryIcon @"local.tiff"
#define LiRendezvousGroupIcon @"rendezvous.tiff"
#define LiNormalGroupIcon @"quickpick.tiff"
#define LiNetworkGroupIcon @"Network (Small).tiff"

// For internal drag-and-drop.
#define LiaisonPboardType @"LiaisonPboardType"

// Load extensions and class posers.
#import "NSFileHandleExtensions.h"
#import "LiTableView.h"