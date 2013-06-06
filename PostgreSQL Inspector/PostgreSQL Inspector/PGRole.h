//
//  PGRole.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGSchemaObject.h"

@interface PGRole : PGSchemaObject

@property (nonatomic, assign) BOOL superuser;
@property (nonatomic, assign) BOOL inherit;
@property (nonatomic, assign) BOOL createRole;
@property (nonatomic, assign) BOOL createDatabase;
@property (nonatomic, assign) BOOL login;
@property (nonatomic, assign) NSInteger connectionLimit;
@property (nonatomic, strong) NSDate *validUntil;
@property (nonatomic, strong) NSArray *memberships;
@property (nonatomic, assign) BOOL replication;

@end
