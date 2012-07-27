//
//  SqliteReader.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SqliteReader : NSObject {
    @protected
    sqlite3_stmt* command;
    @private
    sqlite3* db;
    int lastResult;
}

@property (nonatomic, readonly) int numberOfColumns;
@property (nonatomic, readonly) int lastResult;

- (id) initWithCommand:(sqlite3_stmt*)theCommand database:(sqlite3*) theDatabase;
- (BOOL) readWithError:(NSError**)error;

- (BOOL) getBool:(int)column;
- (int) getInt32:(int)column;
- (NSString*) getString:(int)column;
- (id) getValue:(int)column;
- (NSString*) getSqlRepresentation:(int)column;
- (BOOL) isDBNull:(int)column;

- (NSString*) getName:(int)column;

@end
