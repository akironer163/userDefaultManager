//
//  XNUserDefaultsManager.h
//  XNClient
//
//  Created by usr on 16/2/22.
//  Copyright © 2016年. All rights reserved.
//

@interface XNUserDefaultsManager : MDFSingleton

- (void)setBool:(BOOL)value forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (void)setString:(NSString *)value forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

@end
