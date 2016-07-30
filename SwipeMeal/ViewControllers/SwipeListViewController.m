//
//  SwipeListViewController.m
//  SwipeMeal
//
//  Created by Jacob Harris on 7/29/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "SwipeListViewController.h"
#import "Swipe.h"
#import "SwipeListTableViewCell.h"
@import Firebase;

@interface SwipeListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) FIRDatabaseReference *dbRef;

@end

@implementation SwipeListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dbRef = [[FIRDatabase database] reference];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Create a test Swipe
    [self createNewSwipes];
}

- (void)createNewSwipes {
    NSString *userID = [FIRAuth auth].currentUser.uid;
    NSString *key = [[self.dbRef child:@"swipes"] childByAutoId].key;
    Swipe *swipe = [[self swipes] objectAtIndex:0];
    NSDictionary *swipeDict = @{@"uid":userID,
                                @"price":swipe.price,
                                @"seller_name":swipe.sellerName,
                                @"listing_time":@(swipe.listingTime),
                                @"location_name":swipe.locationName,
                                @"seller_rating":@(swipe.sellerRating)};
    NSDictionary *childUpdates = @{[@"/swipes/" stringByAppendingString:key]: swipeDict,
                                   [NSString stringWithFormat:@"/user-swipes/%@/%@/", userID, key]: swipeDict};
    
    [self.dbRef updateChildValues:childUpdates];
}

- (NSArray *)swipes {
    Swipe *swipe1 = [[Swipe alloc] init];
    swipe1.price = @15;
    swipe1.sellerImage = [UIImage imageNamed:@"temp-greg"];
    swipe1.sellerName = @"Greg K.";
    swipe1.listingTime = [NSDate timeIntervalSinceReferenceDate];
    swipe1.locationName = @"Cafeteria";
    swipe1.sellerRating = 4;
    
    Swipe *swipe2 = [[Swipe alloc] init];
    swipe2.price = @8;
    swipe2.sellerImage = [UIImage imageNamed:@"temp-gabe"];
    swipe2.sellerName = @"Gabe K.";
    swipe2.listingTime = [NSDate timeIntervalSinceReferenceDate];
    swipe2.locationName = @"Building 1";
    swipe2.sellerRating = 5;
    
    Swipe *swipe3 = [[Swipe alloc] init];
    swipe3.price = @17;
    swipe3.sellerImage = [UIImage imageNamed:@"temp-greg"];
    swipe3.sellerName = @"Greg K.";
    swipe3.listingTime = [NSDate timeIntervalSinceReferenceDate];
    swipe3.locationName = @"Cafeteria";
    swipe3.sellerRating = 4;
    
    NSArray *swipes = @[swipe1, swipe2, swipe3];
    return swipes;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [[self swipes] count];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SwipeListTableViewCell *cell = (SwipeListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SwipeListTableViewCell"];
    Swipe *swipe = [[self swipes] objectAtIndex:indexPath.row];
    cell.swipe = swipe;
    
    return cell;
}

@end