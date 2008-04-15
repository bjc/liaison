/*
 *  RenIPC.h
 *  Liaison
 *
 *  Created by Brian Cully on Thu Mar 20 2003.
 *  Copyright (c) 2003 Brian Cully. All rights reserved.
 *
 */

// Rendezvous port name.
#define LiRendezvousPortName @"_liaison._tcp."

// Notifications of death.
#define SERVERMANAGERDEATHNOTIFICATION @"Server Died"
#define CLIENTMANAGERDEATHNOTIFICATION @"Client Died"

// Client/server keys.
#define RenHostnameKey @"hostname"
#define RenFilesAddedKey @"files added"
#define RenFilesChangedKey @"files changed"
#define RenFilesRemovedKey @"files removed"