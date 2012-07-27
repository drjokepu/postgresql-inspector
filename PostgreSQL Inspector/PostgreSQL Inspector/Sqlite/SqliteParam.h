//
//  SqliteParam.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SqliteParam : NSObject {
    @protected
    NSString* name;
}

@property (nonatomic, copy) NSString* name;

- (id) initWithName:(NSString*)theName;
- (void) bindTo:(sqlite3_stmt*)command;

- (int)getIndex:(sqlite3_stmt*)command;

+ (SqliteParam*) sqliteParamWithName:(NSString*)name value:(id)value;

@end
