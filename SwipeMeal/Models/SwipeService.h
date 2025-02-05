//
//  SwipeService.h
//  SwipeMeal
//
//  Created by Jacob Harris on 8/14/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Swipe.h"

@interface SwipeService : NSObject

@property (strong, nonatomic, readonly) NSArray *swipes;
+ (SwipeService *)sharedSwipeService;
- (Swipe *)swipeForKey:(NSString *)key;
- (void)listenForEventsWithAddBlock:(void(^)(void))addBlock removeBlock:(void(^)(void))removeBlock updateBlock:(void(^)(void))updateBlock;
- (void)createNewSwipeWithValues:(NSDictionary *)values withCompletionBlock:(void (^)(NSString *swipeKey))completionBlock;
- (void)buySwipeWithSwipeID:(NSString *)swipeID completionBlock:(void (^)(NSError *error))completionBlock;
- (void)getSwipeWithSwipeID:(NSString *)swipeID completionBlock:(void (^)(Swipe *swipe))completionBlock;

@end
