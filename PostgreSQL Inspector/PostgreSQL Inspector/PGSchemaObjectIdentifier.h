//
//  PGSchemaIdentifier.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGSchemaObjectIdentifier : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger oid;

-(id)initWithName:(NSString*)theName;
-(id)initWithName:(NSString*)theName oid:(NSInteger)theOid;

@end
