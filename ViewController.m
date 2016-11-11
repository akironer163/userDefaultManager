//
//  ViewController.m
//  demo
//
//  Created by user on 16/11/9.
//  Copyright © 2016年 user. All rights reserved.
//

#import "ViewController.h"
#include <stdio.h>
#include <string.h>
#import<objc/runtime.h>


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

@interface ViewController ()

@property (nonatomic, strong) NSMutableDictionary *mapping;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation ViewController

@dynamic desc;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self demo];
    self.desc = @"fxxx";
    
}



- (void)demo {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);//获得类的属性列表
    
    self.mapping = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property); //获得属性名
        const char *attributes = property_getAttributes(property); //获得属性的特性 包括数据类型 weak readonly等
        
        NSLog(@"%@",[NSString stringWithCString:name encoding:NSUTF8StringEncoding]);
#warning 1
        NSLog(@"attributes： %@",[NSString stringWithCString:attributes encoding:NSUTF8StringEncoding]); //T@"NSString",C,N,Gdesc,Sdick:,V_desc

        char *getter = strstr(attributes, ",G"); //,G代表特性是getter strstr(str1,str2) 函数用于判断字符串str2是否是str1的子串。如果是，则该函数返回str2在str1中首次出现的地址；否则，返回NULL
#warning 2
        NSLog(@"getter,G： %s",getter); //,Gdesc,Sdick:,V_desc
        
        if (getter) {
            getter = strdup(getter + 2); //strdup()c中常用的字符串拷贝库函数，一般和free()成对出现
#warning 3
            NSLog(@"getter+2： %s",getter); //desc,Sdick:,V_desc
            
            getter = strsep(&getter, ","); //strsep()用于分解字符串为一组字符串 返回从,开头开始的一个个子串，当没有分割的子串时返回NULL。    定义语句为char *strsep(char **stringp, const char *delim); strsep()/strtok()函数都会修改源字符串，可以使用strdupa（由allocate函数实现）或strdup（由malloc函数实现）保护源字符串。 strtok()已经废弃，使用更高效的strsep(）
#warning 4
            NSLog(@"getter!=null： %s",getter);//desc
            
        } else {
            getter = strdup(name);
            NSLog(@"getter == null %s",getter);
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
        
        NSString *key = [NSString stringWithFormat:@"%s", name];
        
        NSLog(@"%@",key);
        // key： setAge:      value : age
        [self.mapping setValue:key forKey:NSStringFromSelector(getterSel)];
        [self.mapping setValue:key forKey:NSStringFromSelector(setterSel)];
        
        IMP getterImp = NULL;
        IMP setterImp = NULL;
        char type = attributes[1];
        
        NSLog(@"attributes[1]： %c",type);
        
        
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
        
        NSLog(@"type: %c  types: %s",type,types);
        
        
        /*
         snprintf()，为函数原型int snprintf(char *str, size_t size, const char *format, ...)。
         将可变个参数(...)按照format格式化成字符串，然后将其复制到str中
         (1) 如果格式化后的字符串长度 < size，则将此字符串全部复制到str中，并给其后添加一个字符串结束符('\0')；
         (2) 如果格式化后的字符串长度 >= size，则只将其中的(size-1)个字符复制到str中，并给其后添加一个字符串结束符('\0')，返回值为欲写入的字符串长度
         */
        
        /*
         
         snprintf(types, 4, "%c@:", @"c", @"", @"3", @"4");
         
         types = 1@:2@:3@:4@:
         
         */
        
        
        snprintf(types, 4, "%c@:", type);
#warning 5
        NSLog(@"type--- %s",types);
        
        class_addMethod([self class], getterSel, getterImp, types);
        
        snprintf(types, 5, "v@:%c", type);
        
        NSLog(@"type--- %s",types);
        class_addMethod([self class], setterSel, setterImp, types);
    }
    
    free(properties);
    
    

}

- (NSString *)defaultsKeyForSelector:(SEL)selector
{
    return [self.mapping objectForKey:NSStringFromSelector(selector)];
}


- (void)setAge:(int)age{
    
    longLongGetter(self, @selector(setAge:));
}

static long long longLongGetter(ViewController *self, SEL _cmd)
{
    //
    NSString *key = [self defaultsKeyForSelector:_cmd];
    //从沙盒中取出数据
    return [[self.userDefaults objectForKey:key] longLongValue];
}

static void longLongSetter(ViewController *self, SEL _cmd, long long value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    NSNumber *object = [NSNumber numberWithLongLong:value];
    [self.userDefaults setObject:object forKey:key];
    [self.userDefaults synchronize];
}

static bool boolGetter(ViewController *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults boolForKey:key];
}

static void boolSetter(ViewController *self, SEL _cmd, bool value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setBool:value forKey:key];
    [self.userDefaults synchronize];
}

static int integerGetter(ViewController *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return (int)[self.userDefaults integerForKey:key];
}

static void integerSetter(ViewController *self, SEL _cmd, int value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setInteger:value forKey:key];
    [self.userDefaults synchronize];
}

static float floatGetter(ViewController *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults floatForKey:key];
}

static void floatSetter(ViewController *self, SEL _cmd, float value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setFloat:value forKey:key];
    [self.userDefaults synchronize];
}

static double doubleGetter(ViewController *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults doubleForKey:key];
}

static void doubleSetter(ViewController *self, SEL _cmd, double value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setDouble:value forKey:key];
    [self.userDefaults synchronize];
}

static id objectGetter(ViewController *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    
    NSLog(@"key: %@   %@",key,[self.userDefaults objectForKey:key]);
    
    return [self.userDefaults objectForKey:key];
}

static void objectSetter(ViewController *self, SEL _cmd, id object)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    if (object) {
        [self.userDefaults setObject:object forKey:key];
    } else {
        [self.userDefaults removeObjectForKey:key];
    }
    
    [self.userDefaults synchronize];
    
    
}

@end
