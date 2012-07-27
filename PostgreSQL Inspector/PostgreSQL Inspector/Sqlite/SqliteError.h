//
//  SqliteError.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SqliteError : NSError

@property (nonatomic, strong) NSString *errorDescription;

-(id) initWithDatabase:(sqlite3*) db;
-(id) initWithCStringDescription:(char*)theErrorDescription;
-(id) initWithErrorCode:(int)errorCode;

+ (SqliteError*) errorWithErrorCode:(int)errorCode;
+ (NSString*) descriptionForErrorCode:(int)errorCode;

@end
