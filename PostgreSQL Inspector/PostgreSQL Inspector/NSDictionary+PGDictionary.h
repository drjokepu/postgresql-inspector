//
//  NSDictionary+PGDictionary.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/12/2012.
//
//

#import <Foundation/Foundation.h>

typedef struct
{
    size_t length;
    char **keys;
    char **values;
} PGNullTerminatedKeysAndValues;

extern void PGFreeNullTerminatedKeysAndValues(PGNullTerminatedKeysAndValues *obj);

@interface NSDictionary (PGDictionary)

-(PGNullTerminatedKeysAndValues*)copyToNullTerminatedArrays __attribute__((objc_method_family(none)));

@end
