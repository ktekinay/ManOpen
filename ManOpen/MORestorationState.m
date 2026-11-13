//
//  MORestorationState.m
//  ManOpen (Application)
//
//  Created by Kem Tekinay on 11/13/26.
//

#import "MORestorationState.h"

NSString * const MORestoreWindowInfoKey   = @"RestoreWindowInfo";
NSString * const MORestoreNameKey         = @"Name";
NSString * const MORestoreSectionKey      = @"Section";
NSString * const MORestoreTitleKey        = @"Title";
NSString * const MORestoreFileURLKey      = @"URL";
NSString * const MORestoreFileTypeKey     = @"DocType";

NSString * const MORestoreSearchStringKey = @"SearchString";
NSString * const MORestoreAproposTitleKey = @"Title";

static BOOL IsStringOrAbsent(id value)
{
    return value == nil || [value isKindOfClass:[NSString class]];
}

NSDictionary<NSString *, id> *MOValidatedManPageRestoreInfo(id object)
{
    if (![object isKindOfClass:[NSDictionary class]])
        return nil;

    NSDictionary *info = object;
    id name = info[MORestoreNameKey];
    id url = info[MORestoreFileURLKey];

    if (name != nil)
    {
        id section = info[MORestoreSectionKey];
        id title = info[MORestoreTitleKey];

        if (![name isKindOfClass:[NSString class]] || [name length] == 0)
            return nil;
        if (!IsStringOrAbsent(section) || !IsStringOrAbsent(title))
            return nil;

        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        result[MORestoreNameKey] = name;
        result[MORestoreTitleKey] = ([title length] > 0) ? title : name;
        if ([section length] > 0)
            result[MORestoreSectionKey] = section;
        return [result copy];
    }

    if (url != nil)
    {
        static NSSet<NSString *> *fileTypes;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            fileTypes = [NSSet setWithObjects:@"man", @"mangz", @"cat", @"catgz", nil];
        });

        id type = info[MORestoreFileTypeKey];

        if (![url isKindOfClass:[NSURL class]] || ![url isFileURL])
            return nil;
        if (![type isKindOfClass:[NSString class]] || ![fileTypes containsObject:type])
            return nil;

        return @{ MORestoreFileURLKey: url, MORestoreFileTypeKey: type };
    }

    return nil;
}

NSDictionary<NSString *, id> *MODecodeManPageRestoreInfo(NSCoder *coder)
{
    @try
    {
        if (![coder containsValueForKey:MORestoreWindowInfoKey])
            return nil;

        NSSet *classes = [NSSet setWithObjects:[NSDictionary class], [NSString class], [NSURL class], nil];
        id object = [coder decodeObjectOfClasses:classes forKey:MORestoreWindowInfoKey];

        return MOValidatedManPageRestoreInfo(object);
    }
    @catch (NSException *exception)
    {
        // A coder set to raise on decoding failures throws for disallowed classes.
        return nil;
    }
}

NSDictionary<NSString *, NSString *> *MODecodeAproposRestoreInfo(NSCoder *coder)
{
    @try
    {
        if (![coder containsValueForKey:MORestoreSearchStringKey])
            return nil;

        id search = [coder decodeObjectOfClass:[NSString class] forKey:MORestoreSearchStringKey];
        id title = [coder decodeObjectOfClass:[NSString class] forKey:MORestoreAproposTitleKey];

        if (![search isKindOfClass:[NSString class]])
            return nil;
        if (![title isKindOfClass:[NSString class]] || [title length] == 0)
            title = search;

        return @{ MORestoreSearchStringKey: search, MORestoreAproposTitleKey: title };
    }
    @catch (NSException *exception)
    {
        return nil;
    }
}
