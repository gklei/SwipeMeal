//
//  SwipeService.m
//  SwipeMeal
//
//  Created by Jacob Harris on 8/14/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "SwipeService.h"
#import "SwipeStore.h"
#import "SwipeMeal-Swift.h"

@import Firebase;

@interface SwipeService ()

@property (strong, nonatomic) FIRDatabaseReference *dbRef;
@property (strong, nonatomic) SwipeStore *swipeStore;

@end

@implementation SwipeService

+ (SwipeService *)sharedSwipeService {
    static SwipeService *swipeService = nil;
    if (!swipeService) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            swipeService = [[SwipeService alloc] init];
        });
    }
    
    return swipeService;
}

- (instancetype)init {
    if (self = [super init]) {
        self.swipeStore = [SwipeStore sharedSwipeStore];
        self.dbRef = [[FIRDatabase database] reference];
    }
    
    return self;
}

- (NSArray *)swipes {
    return [self.swipeStore swipesSortedByPriceAscending];
}

- (Swipe *)swipeForKey:(NSString *)key {
    return [self.swipeStore swipeForKey:key];
}

- (void)listenForEventsWithAddBlock:(void (^)(void))addBlock removeBlock:(void (^)(void))removeBlock updateBlock:(void (^)(void))updateBlock {
    [[self.dbRef child:@"/swipes-listed/"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Test for expired Swipe
        if (![self snapshotIsExpired:snapshot]) {
            // Test for active seller
            [self sellerIsActiveWithSnapshot:snapshot completionBlock:^{
                // Build Swipe
                Swipe *swipe = [self swipeWithKey:snapshot.key values:snapshot.value];
					NSString* currentUserGroupName = [SMDatabaseLayer groupNameForUser:[FIRAuth auth].currentUser];
					
                if (!swipe.soldTime && [swipe.sellerGroupName isEqualToString: currentUserGroupName]) {
                    [self.swipeStore addSwipe:swipe forKey:swipe.swipeID];
                    NSLog(@"Added Swipe: %@", swipe);
                    addBlock();
                } else {
                    [self.swipeStore removeSwipeForKey:swipe.swipeID];
                    NSLog(@"Removed Swipe: %@", swipe);
                    removeBlock();
                }
            }];
        }
    }];
    
    [[self.dbRef child:@"/swipes-listed/"] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        Swipe *swipe = [self swipeWithKey:snapshot.key values:snapshot.value];
        if (swipe.soldTime) {
            [self.swipeStore removeSwipeForKey:swipe.swipeID];
        } else {
            [self.swipeStore addSwipe:swipe forKey:swipe.swipeID];
        }
        NSLog(@"Updated Swipe: %@", swipe);
        updateBlock();
    }];
}

- (BOOL)snapshotIsExpired:(FIRDataSnapshot *)snapshot {
    NSTimeInterval expirationTimestamp = [[snapshot.value objectForKey:@"expiration_time"] floatValue];
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    if (currentTimestamp >= expirationTimestamp) {
        return YES;
    }
    
    return NO;
}

- (void)sellerIsActiveWithSnapshot:(FIRDataSnapshot *)snapshot completionBlock:(void (^)(void))completionBlock {
    NSString *sellerID = [snapshot.value objectForKey:@"uid"];
    [[[self.dbRef child:@"users"] child:sellerID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *sellStatus = [snapshot.value objectForKey:@"stripe_account_status"];
        if ([sellStatus isEqualToString:@"active"]) {
            completionBlock();
        }
    }];
}

- (Swipe *)swipeWithKey:(NSString *)key values:(NSDictionary *)values {
    Swipe *swipe = [[Swipe alloc] init];
    swipe.swipeID = key;
    swipe.listingUserID = [values objectForKey:@"uid"];
    swipe.listingUserName = [values objectForKey:@"seller_name"];
    swipe.listingUserRating = [[values objectForKey:@"seller_rating"] integerValue];
    swipe.listPrice = [[values objectForKey:@"price"] integerValue];
    swipe.locationName = [values objectForKey:@"location_name"];
    swipe.listingTime = [[values objectForKey:@"listing_time"] integerValue];
    swipe.expireTime = [[values objectForKey:@"expiration_time"] integerValue];
	swipe.availableTime = [[values objectForKey:@"available_time"] integerValue];
    swipe.soldTime = [[values objectForKey:@"sold_time"] integerValue];
    swipe.swipeTransactionID = [values objectForKey:@"swipe_transaction_id"];
	swipe.sellerGroupName = [values objectForKey:@"seller_group_name"];

    return swipe;
}

- (void)createNewSwipeWithValues:(NSDictionary *)values withCompletionBlock:(void (^)(NSString *swipeKey))completionBlock {
    NSString *key = [[self.dbRef child:@"swipes-listed"] childByAutoId].key;
    NSString *userID = [FIRAuth auth].currentUser.uid;
    NSDictionary *childUpdates = @{[@"/swipes-listed/" stringByAppendingString:key]: values,
                                   [NSString stringWithFormat:@"/user-swipes-listed/%@/%@/", userID, key]: values};
    
    [self.dbRef updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            completionBlock(key);
        }
    }];
   
   [SwipeMealPushCoordinator notifyUsersOfAvailableSwipe];
}

- (void)getSwipeWithSwipeID:(NSString *)swipeID completionBlock:(void (^)(Swipe *swipe))completionBlock {
    [[[self.dbRef child:@"/swipes-listed/"] child:swipeID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        Swipe *swipe = [self swipeWithKey:snapshot.key values:snapshot.value];
        [self.swipeStore addSwipe:swipe forKey:swipeID];
        if (swipe) {
            completionBlock(swipe);
        } else {
            completionBlock(nil);
        }
    }];
}

- (void)buySwipeWithSwipeID:(NSString *)swipeID completionBlock:(void (^)(NSError *))completionBlock {
    [self getSwipeWithSwipeID:swipeID completionBlock:^(Swipe *swipe) {
        NSString *userID = [FIRAuth auth].currentUser.uid;
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        NSDictionary *swipeDict = @{@"uid":userID,
                                    @"sold_time":@(timestamp),
                                    @"price":@(swipe.listPrice),
                                    @"seller_name":swipe.listingUserName,
                                    @"listing_time":@(swipe.listingTime),
                                    @"location_name":swipe.locationName,
                                    @"fee":@200,
                                    @"seller_rating":@(swipe.listingUserRating)};
        NSDictionary *childUpdates = @{[@"/swipes-listed/" stringByAppendingString:swipe.swipeID]: swipeDict,
                                       [NSString stringWithFormat:@"/user-swipes-listed/%@/%@/", userID, swipe.swipeID]: swipeDict};
        
        [self.dbRef updateChildValues:childUpdates withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (error) {
                completionBlock(error);
            } else {
                completionBlock(nil);
            }
        }];
    }];
}

@end
