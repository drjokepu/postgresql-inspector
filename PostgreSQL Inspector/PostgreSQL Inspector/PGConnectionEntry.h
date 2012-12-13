//
//  PGConnectionEntry.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

@class Sqlite;

@interface PGConnectionEntry : NSObject

@property (nonatomic, assign) NSUInteger objectId;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) NSString *database;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL passwordRetreivedFromKeychain;
@property (nonatomic, assign) BOOL userAskedForStroingPasswordInKeychain;

-(NSDictionary*)connectionParams;

-(void)insert;
-(void)update;
-(void)delete;
-(void)lock;
-(void)unlock;

+(NSUInteger)defaultConnectionPort;
+(NSArray *)getConnectionEntries;

@end
