//
//  PGConstraintColumn.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConstraintColumn.h"

@implementation PGConstraintColumn
@synthesize columnNumber, foreignKeyReferencedColumnNumber, foreignKeyPKFKEqualityOperator, foreignKeyFKFKEqualityOperator, foreignKeyPKPKEqualityOperator, exclusionOperator;

@end
