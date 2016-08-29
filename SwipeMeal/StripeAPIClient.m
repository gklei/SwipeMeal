//
//  StripeAPIClient.m
//  SwipeMeal
//
//  Created by Jacob Harris on 8/27/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "StripeAPIClient.h"
#import "AFNetworking/AFNetworking.h"
#import "Constants.h"
@import Stripe;

@interface StripeAPIClient () <STPBackendAPIAdapter>

@end

@implementation StripeAPIClient

- (void)requestPurchaseWithSwipeID:(NSString *)swipeID buyerID:(NSString *)buyerID sellerID:(NSString *)sellerID completionBlock:(void (^)(void))completionBlock {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    NSDictionary *params = @{@"swipe_id":swipeID,
                             @"buyer":buyerID,
                             @"seller":sellerID,
                             kPaymentServerDevParameter:kPaymentServerDevValue};
    NSString *urlString = [kPaymentServerEndpoint stringByAppendingPathComponent:@"/swipe/buy"];
    NSURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:urlString parameters:params error:nil];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            NSLog(@"%@", responseObject);
        }
    }];

    [dataTask resume];
}

@end