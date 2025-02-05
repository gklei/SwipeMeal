//
//  MessageStore.m
//  SwipeMeal
//
//  Created by Jacob Harris on 8/16/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "MessageStore.h"

@implementation MessageStore {
    NSMutableDictionary *_messagesByMessageID;
}

+ (MessageStore *)sharedMessageStore {
    static MessageStore *messageStore = nil;
    if (!messageStore) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            messageStore = [[MessageStore alloc] init];
        });
    }
    
    return messageStore;
}

- (instancetype)init {
    if (self = [super init]) {
        _messagesByMessageID = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (BOOL)containsMessageKey:(NSString *)key {
    if ([_messagesByMessageID objectForKey:key]) {
        return YES;
    }
    
    return NO;
}

- (void)addMessage:(Message *)message forKey:(NSString *)key {
    [_messagesByMessageID setObject:message forKey:key];
}

- (void)removeMessageForKey:(NSString *)key {
    [_messagesByMessageID removeObjectForKey:key];
}

- (Message *)messageForKey:(NSString *)key {
    Message *message = [_messagesByMessageID objectForKey:key];
    return message;
}

- (NSArray *)messagesSortedByDateDescending {
    NSArray *messageKeys = [_messagesByMessageID keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Message *message1 = (Message *)obj1;
        Message *message2 = (Message *)obj2;
        
        return [@(message2.timestamp) compare:@(message1.timestamp)];
    }];
    
    NSMutableArray *messages = [NSMutableArray array];
    for (NSString *key in messageKeys) {
        Message *message = [_messagesByMessageID objectForKey:key];
        [messages addObject:message];
    }
    
    return messages;
}

@end