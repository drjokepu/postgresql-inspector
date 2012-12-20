//
//  PGIndex.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 19/12/2012.
//
//

#import <Foundation/Foundation.h>
#import "PGConstraintType.h"

@interface PGIndex : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL primary;
@property (nonatomic, assign) BOOL unique;
@property (nonatomic, assign) BOOL clustered;
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) NSString *indexDefinition;
@property (nonatomic, assign) NSString *constraintDefinition;
@property (nonatomic, assign) PGConstraintType constraintType;
@property (nonatomic, assign) BOOL deferrable;
@property (nonatomic, assign) BOOL deferred;
@property (nonatomic, assign) NSUInteger tablespace;

@end
