//
//  SqliteManagedReader.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "SqliteReader.h"


@interface SqliteManagedReader : SqliteReader
{
}

@property (nonatomic, readonly) BOOL closed;

-(void) close;

@end
