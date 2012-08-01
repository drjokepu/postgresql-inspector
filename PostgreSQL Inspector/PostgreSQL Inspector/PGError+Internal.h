//
//  PGError.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 08/01/2012.
//
//

#import <Foundation/Foundation.h>
#import "PGError.h"
#import "px.h"

@interface PGError(Internal)

-(id)initWithPxError:(const px_error*)pxError;

@end
