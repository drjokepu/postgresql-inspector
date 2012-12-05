//
//  NSDictionary+PGDictionary.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/12/2012.
//
//

#import "NSDictionary+PGDictionary.h"

static char *strclone(NSString *source);

@implementation NSDictionary (PGDictionary)

-(PGNullTerminatedKeysAndValues *)copyToNullTerminatedArrays
{
    const NSUInteger length = [self count];
    PGNullTerminatedKeysAndValues *obj = malloc(sizeof(PGNullTerminatedKeysAndValues));
    obj->length = length;
    obj->keys = calloc(length + 1, sizeof(char*));
    obj->values = calloc(length + 1, sizeof(char *));
    NSArray *keys = [self allKeys];
    for (NSUInteger i = 0; i < length; i++)
    {
        NSString *key = keys[i];
        NSString *value = self[key];
        if ([key isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]])
        {
            obj->keys[i] = strclone(key);
            obj->values[i] = strclone(key);
        }
    }
    return obj;
}

@end

void PGFreeNullTerminatedKeysAndValues(PGNullTerminatedKeysAndValues *obj)
{
    for (NSUInteger i = 0; i < obj->length; i++)
    {
        free(obj->keys[i]);
        free(obj->values[i]);
    }
    free(obj->keys);
    free(obj->values);
    free(obj);
}

static char *strclone(NSString *source)
{
    const NSUInteger length = [source length];
    const char *cString = [source UTF8String];
    char *clone = calloc(length + 1, sizeof(char));
    memcpy(clone, cString, length);
    return clone;
}