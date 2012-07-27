//
//  SqliteTools.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "SqliteColumnTypeAffinity.h"
#import "SqliteReader.h"
#import "SqliteManagedReader.h"
#import "SqliteParam.h"
#import "SqliteParamDouble.h"
#import "SqliteParamInt32.h"
#import "SqliteParamInt64.h"
#import "SqliteParamNull.h"
#import "SqliteParamString.h"
#import "SqliteNull.h"

const static NSInteger SqliteFetchAllRows = -1;

@interface Sqlite : NSObject

@property (nonatomic, readonly) BOOL isOpen;
@property (nonatomic, readonly) BOOL isInTransaction;
@property (nonatomic, copy) NSString* databaseFilename;
@property (nonatomic, readonly) sqlite3* db;

- (id) initAndOpen:(NSString*)filename error:(NSError*__autoreleasing*) error;
- (id) initAndOpenTrains2Database;

- (BOOL) open:(NSString*)filename error:(NSError*__autoreleasing*) error;
- (void) close;
- (void) reset;
- (BOOL) backupTo:(NSString*)filename progressCallback:(void(^)(NSInteger remaining, NSInteger pageCount))progressCallback withError:(NSError*__autoreleasing*)error;

- (SqliteManagedReader*) prepare:(const NSString*)commandText parameters:(NSArray*)parameters error:(NSError *__autoreleasing *)error;
- (NSArray*) fetchFrom:(SqliteManagedReader*)reader rows:(NSInteger)rows withReader:(id(^)(SqliteReader* r))read error:(NSError*__autoreleasing*)error ;

- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters reader:(id(^)(SqliteReader* r))read;
- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters error:(NSError *__autoreleasing*)error reader:(id(^)(SqliteReader* r))read;
- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters commitOnChange:(BOOL)commitOnChange error:(NSError *__autoreleasing*)error reader:(id(^)(SqliteReader* r))read;

- (id) readSingle:(const NSString*)commandText parameters:(NSArray*)parameters reader:(id(^)(SqliteReader*))read;
- (id) readSingle:(const NSString*)commandText parameters:(NSArray*)parameters error:(NSError *__autoreleasing*)error reader:(id(^)(SqliteReader* r))read;

- (BOOL) execute:(const NSString*)commandText parameters:(NSArray*)parameters commitOnChange:(BOOL)commitOnChange error:(NSError *__autoreleasing*)error;
- (BOOL) execute:(const NSString*)commandText parameters:(NSArray*)parameters action:(void(^)(SqliteReader* r))action error:(NSError*__autoreleasing*)error;
- (BOOL) executeAll:(const NSString*)commandText error:(NSError *__autoreleasing*)error;
- (id) executeScalar:(const NSString*)commandText;
- (id) executeScalar:(const NSString*)commandText parameters:(NSArray*)parameters;

- (BOOL) updateCellTo:(id)value inTable:(NSString*)tableName column:(NSString*)column rowId:(NSString*)rowId row:(int)row error:(NSError*__autoreleasing*) error;
- (BOOL) deleteRow:(int)row from:(NSString*)tableName rowId:(NSString*)rowId error:(NSError*__autoreleasing*)error;

- (int)numberOfRowsChanged;
- (NSInteger)totalNumberOfRowsChanged;
- (NSInteger)lastInsertedRowId;

- (BOOL) beginTransaction:(NSError*__autoreleasing*)error;
- (BOOL) rollbackTransaction:(NSError*__autoreleasing*)error;
- (BOOL) commitTransaction:(NSError*__autoreleasing*)error;

- (NSString*) description;

- (NSArray*) tableNames;
- (NSArray *)viewNames;

- (BOOL) schemaObjectExists:(NSString *)name;

- (void)attachDatabase:(NSString*)databaseName path:(NSString*)attachedDatabasePath;
- (void)detachDatabase:(NSString*)databaseName;

+ (sqlite3*) openWithFilename:(NSString*)filename error:(NSError*__autoreleasing*)error;
+ (void) close:(sqlite3*)db;
+ (NSSet*) keyWords;
+ (NSString*) identifier:(NSString*)identifier;

@end
