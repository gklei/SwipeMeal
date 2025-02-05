//
//  SwipeSellDetailViewController.m
//  SwipeMeal
//
//  Created by Jacob Harris on 7/31/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "SwipeSellDetailViewController.h"
#import "SwipeSellConfirmationViewController.h"
#import "SwipeService.h"
#import "MessageService.h"
#import "Constants.h"
#import "SwipeMeal-Swift.h"
@import Firebase;

@interface SwipeSellDetailViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UILabel *confirmPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *confirmTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *confirmLocationLabel;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (strong, nonatomic) SwipeService *swipeService;
@property (strong, nonatomic) MessageService *messageService;
@property (strong, nonatomic) FIRDatabaseReference *dbRef;

@end

@implementation SwipeSellDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.topImageView.layer.masksToBounds = YES;
    self.swipeService = [SwipeService sharedSwipeService];
    self.messageService = [MessageService sharedMessageService];

    self.confirmPriceLabel.text = [NSString stringWithFormat:@"$%ld", (long)self.swipe.listPrice / 100];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.swipe.availableTime];
    self.confirmTimeLabel.text = [self timeStringFromDate:date];
    self.confirmLocationLabel.text = self.swipe.locationName;
    
    self.dbRef = [[FIRDatabase database] reference];
}

- (NSString *)timeStringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mm a"];
    
    NSString *timeString = [formatter stringFromDate:date];
    return timeString;
}

- (void)createNewSwipe {
    NSString *userID = [FIRAuth auth].currentUser.uid;
    NSString *userName = [FIRAuth auth].currentUser.displayName;
	NSString* groupName = [SMDatabaseLayer groupNameForUser:[FIRAuth auth].currentUser];
	
    // Listing timestamp
    NSDate *listingDate = [NSDate date];
    NSTimeInterval listingTimestamp = [listingDate timeIntervalSince1970];

    // Expiration timestamp
    NSDate *expirationDate = [[NSDate dateWithTimeIntervalSince1970:self.swipe.availableTime] dateByAddingTimeInterval:60 * 60 * 24];
    NSTimeInterval expirationTimestamp = [expirationDate timeIntervalSince1970];
    
    NSDictionary *swipeDict = @{@"uid":userID,
                                @"seller_name":userName,
                                @"listing_time":@(listingTimestamp),
                                @"expiration_time":@(expirationTimestamp),
                                @"available_time":@(self.swipe.availableTime),
                                @"price":@(self.swipe.listPrice),
                                @"fee":@200,
                                @"location_name":self.swipe.locationName,
                                @"seller_rating":@(self.swipe.listingUserRating),
										  @"seller_group_name" : groupName};
    
    [self.swipeService createNewSwipeWithValues:swipeDict withCompletionBlock:^(NSString *swipeKey) {
        // Create initial message
        NSString *body = @"Your Swipe has been posted. You can accept Swipe requests via Messages.";
        NSDictionary *messageValues = @{@"swipe_id":swipeKey,
                                        @"from_uid":kSwipeMealSystemUserID,
                                        @"from_name":@"Swipe Crew",
                                        @"to_uid":userID,
                                        @"timestamp":@(listingTimestamp),
                                        @"unread":@(YES),
                                        @"is_offer_message":@(NO),
                                        @"body":body};
        [self.messageService createNewMessageWithValues:messageValues withCompletionBlock:^{
            SwipeSellConfirmationViewController *swipeSellConfirmationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SwipeSellConfirmationViewController"];
            [self.tabBarController presentViewController:swipeSellConfirmationViewController animated:YES completion:nil];
        }];
    }];
}

- (IBAction)didTapContinueButton:(UIButton *)sender {
    NSString *userID = [FIRAuth auth].currentUser.uid;
    [[[self.dbRef child:@"users"] child:userID] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSString *sellStatus = [snapshot.value objectForKey:@"stripe_account_status"];
        if ([sellStatus isEqualToString:@"active"]) {
            [self createNewSwipe];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"More info needed"
                                                                                     message:@"Please enter your details on the Wallet tab in order to list this Swipe for sale."
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
            [alertController addAction:action];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

@end
