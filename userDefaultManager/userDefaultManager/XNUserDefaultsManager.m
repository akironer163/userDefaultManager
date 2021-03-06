//
//  XNUserDefaultsManager.m
//  XNClient
//
//  Created by usr on 16/2/22.
//  Copyright © 2016年  All rights reserved.
//

#import "XNUserDefaultsManager.h"
#import <objc/runtime.h>

typedef NS_ENUM(char, XNTypeEncodings) {
    Char                = 'c',
    Bool                = 'B',
    Short               = 's',
    Int                 = 'i',
    Long                = 'l',
    LongLong            = 'q',
    UnsignedChar        = 'C',
    UnsignedShort       = 'S',
    UnsignedInt         = 'I',
    UnsignedLong        = 'L',
    UnsignedLongLong    = 'Q',
    Float               = 'f',
    Double              = 'd',
    Object              = '@'
};

@interface XNUserDefaultsManager ()

@property (nonatomic, strong) NSMutableDictionary *mapping; //
@property (nonatomic, strong) NSUserDefaults *userDefaults; //

@end

@implementation XNUserDefaultsManager

- (NSUserDefaults *)userDefaults ;
{
    if (!_userDefaults) {
        NSString *suiteName = nil;
        
        if ([NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)]) {
            suiteName = [self _suiteName];
        }
        
        if (suiteName && suiteName.length) {
            _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        } else {
            _userDefaults = [NSUserDefaults standardUserDefaults];
        }
    }
    
    return _userDefaults;
}

- (NSString *)defaultsKeyForPropertyNamed:(char const *)propertyName
{
    NSString *key = [NSString stringWithFormat:@"%s", propertyName];
    return [self _transformKey:key];
}

- (NSString *)defaultsKeyForSelector:(SEL)selector
{
    return [self.mapping objectForKey:NSStringFromSelector(selector)];
}

static long long longLongGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [[self.userDefaults objectForKey:key] longLongValue];
}

static void longLongSetter(XNUserDefaultsManager *self, SEL _cmd, long long value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    NSNumber *object = [NSNumber numberWithLongLong:value];
    [self.userDefaults setObject:object forKey:key];
    [self.userDefaults synchronize];
}

static bool boolGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults boolForKey:key];
}

static void boolSetter(XNUserDefaultsManager *self, SEL _cmd, bool value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setBool:value forKey:key];
    [self.userDefaults synchronize];
}

static int integerGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return (int)[self.userDefaults integerForKey:key];
}

static void integerSetter(XNUserDefaultsManager *self, SEL _cmd, int value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setInteger:value forKey:key];
    [self.userDefaults synchronize];
}

static float floatGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults floatForKey:key];
}

static void floatSetter(XNUserDefaultsManager *self, SEL _cmd, float value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setFloat:value forKey:key];
    [self.userDefaults synchronize];
}

static double doubleGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults doubleForKey:key];
}

static void doubleSetter(XNUserDefaultsManager *self, SEL _cmd, double value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setDouble:value forKey:key];
    [self.userDefaults synchronize];
}

static id objectGetter(XNUserDefaultsManager *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults objectForKey:key];
}

static void objectSetter(XNUserDefaultsManager *self, SEL _cmd, id object)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    if (object) {
        [self.userDefaults setObject:object forKey:key];
    } else {
        [self.userDefaults removeObjectForKey:key];
    }
    [self.userDefaults synchronize];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"

- (instancetype)init
{
    self = [super init];
    if (self) {
        SEL setupDefaultSEL = NSSelectorFromString(@"setupDefaults");
        if ([self respondsToSelector:setupDefaultSEL]) {
            NSDictionary *defaults = [self performSelector:setupDefaultSEL];
            NSMutableDictionary *mutableDefaults = [NSMutableDictionary dictionaryWithCapacity:[defaults count]];
            for (NSString *key in defaults) {
                id value = [defaults objectForKey:key];
                NSString *transformedKey = [self _transformKey:key];
                [mutableDefaults setObject:value forKey:transformedKey];
            }
            [self.userDefaults registerDefaults:mutableDefaults];
        }
        
        [self generateAccessorMethods];
    }
    
    return self;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key;
{
    [self.userDefaults setBool:value forKey:key];
    [self.userDefaults synchronize];
}

- (BOOL)boolForKey:(NSString *)key;
{
    return [self.userDefaults boolForKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self.userDefaults removeObjectForKey:key];
    [self.userDefaults synchronize];
}

- (void)setString:(NSString *)value forKey:(NSString *)key
{
    [self.userDefaults setObject:value forKey:key];
    [self.userDefaults synchronize];
}

- (NSString *)stringForKey:(NSString *)key
{
    return [self.userDefaults stringForKey:key];
}

- (NSString *)_transformKey:(NSString *)key
{
    if ([self respondsToSelector:@selector(transformKey:)]) {
        return [self performSelector:@selector(transformKey:) withObject:key];
    }
    
    return key;
}

- (NSString *)_suiteName
{
    if ([self respondsToSelector:@selector(suiteName)]) {
        return [self performSelector:@selector(suiteName)];
    }
    
    return nil;
}

#pragma GCC diagnostic pop

- (void)generateAccessorMethods
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    self.mapping = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        
        char *getter = strstr(attributes, ",G");
        if (getter) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        SEL getterSel = sel_registerName(getter);
        free(getter);
        
        char *setter = strstr(attributes, ",S");
        if (setter) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSel = sel_registerName(setter);
        free(setter);
        
        NSString *key = [self defaultsKeyForPropertyNamed:name];
        [self.mapping setValue:key forKey:NSStringFromSelector(getterSel)];
        [self.mapping setValue:key forKey:NSStringFromSelector(setterSel)];
        
        IMP getterImp = NULL;
        IMP setterImp = NULL;
        char type = attributes[1];
        switch (type) {
            case Short:
            case Long:
            case LongLong:
            case UnsignedChar:
            case UnsignedShort:
            case UnsignedInt:
            case UnsignedLong:
            case UnsignedLongLong:
                getterImp = (IMP)longLongGetter;
                setterImp = (IMP)longLongSetter;
                break;
                
            case Bool:
            case Char:
                getterImp = (IMP)boolGetter;
                setterImp = (IMP)boolSetter;
                break;
                
            case Int:
                getterImp = (IMP)integerGetter;
                setterImp = (IMP)integerSetter;
                break;
                
            case Float:
                getterImp = (IMP)floatGetter;
                setterImp = (IMP)floatSetter;
                break;
                
            case Double:
                getterImp = (IMP)doubleGetter;
                setterImp = (IMP)doubleSetter;
                break;
                
            case Object:
                getterImp = (IMP)objectGetter;
                setterImp = (IMP)objectSetter;
                break;
                
            default:
                free(properties);
                [NSException raise:NSInternalInconsistencyException format:@"Unsupported type of property \"%s\" in class %@", name, self];
                break;
        }
        
        char types[5];
        
        snprintf(types, 4, "%c@:", type);
        class_addMethod([self class], getterSel, getterImp, types);
        
        snprintf(types, 5, "v@:%c", type);
        class_addMethod([self class], setterSel, setterImp, types);
    }
    
    free(properties);
}

@end
