//
//  PGSchema.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGSchemaObject.h"

@interface PGSchema : PGSchemaObject
@property (nonatomic, assign) NSInteger owner;
@property (nonatomic, strong) NSString *ownerName;

-(NSString*)createDdl;

@end
