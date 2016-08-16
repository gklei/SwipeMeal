//
//  Message.h
//  SwipeMeal
//
//  Created by Jacob Harris on 6/25/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Message : NSObject

@property (strong, nonatomic) UIImage *mainImage;
@property (strong, nonatomic) NSString *nameText;
@property (strong, nonatomic) NSString *fromUID;
@property (strong, nonatomic) NSString *toUID;
@property (strong, nonatomic) NSString *swipeID;
@property (strong, nonatomic) NSString *dateTimeText;
@property (strong, nonatomic) NSString *messageText;
@property (nonatomic, getter=isUnread) BOOL unread;

@end