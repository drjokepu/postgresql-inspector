//
//  PGDatabase.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

@class PGConnection, PGConnectionEntry;

#import <Foundation/Foundation.h>
#import "PGCommandDelegate.h"
#import "PGDatabaseDelegate.h"

@interface PGDatabase : NSObject <PGCommandDelegate>

@property (nonatomic, strong) PGConnectionEntry *connectionEntry;
@property (nonatomic, strong) NSArray *schemaNames;
@property (nonatomic, strong) NSDictionary *schemaNameLookup;
@property (nonatomic, strong) NSArray *schemaObjectGroups;
@property (nonatomic, strong) NSArray *roles;
@property (nonatomic, assign) NSInteger publicSchemaIndex;
@property (nonatomic, weak) id<PGDatabaseDelegate> delegate;

-(id)initWithConnectionEntry:(PGConnectionEntry*)theConnectionEntry;
-(void)loadSchema:(PGConnection*)connection;
+(NSArray*)commonTypes;

@end
