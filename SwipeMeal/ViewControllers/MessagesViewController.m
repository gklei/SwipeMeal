//
//  MessagesViewController.m
//  SwipeMeal
//
//  Created by Jacob Harris on 6/25/16.
//  Copyright © 2016 Incipia. All rights reserved.
//

#import "MessagesViewController.h"
#import "MessagesTableViewCell.h"
#import "Message.h"
#import "MessagesDetailViewController.h"
#import "MessageService.h"
#import "SwipeMeal-Swift.h"
@import Firebase;

@interface MessagesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UINavigationBar *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) Message *selectedMessage;
@property (strong, nonatomic) MessageService *messageService;

@end

@implementation MessagesViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navBarView.translucent = NO;
    self.tabBarController.tabBar.tintColor = [[UIColor alloc] initWithHexString:@"6BB739"];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];

    // Listen for notifications telling us that a message detail window has been tapped to close
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeMessageDetail) name:@"didTapToCloseMessageDetail" object:nil];
    
    self.messageService = [MessageService sharedMessageService];
    [self.messageService listenForEventsWithAddBlock:^{
        [self.tableView reloadData];
    } removeBlock:^{
        [self.tableView reloadData];
    } updateBlock:^{
        [self.tableView reloadData];
    }];
}

- (void)closeMessageDetail {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self.messageService.messages count];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessagesTableViewCell *cell = (MessagesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"MessagesTableViewCell" forIndexPath:indexPath];
    Message *message = [self.messageService.messages objectAtIndex:indexPath.row];
    
    [cell setUpWithMessage:message];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    // Image
    if (!message.mainImage) {
        [self startDownloadingProfileImageForUserID:message.fromUID atIndexPath:indexPath];
    }

    // Cell background color
    if (indexPath.row % 2) {
        cell.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Message *message = [self.messageService.messages objectAtIndex:indexPath.row];
    self.selectedMessage = message;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"MessagesViewController_MessagesDetailViewController" sender:nil];
    });
}

- (void)startDownloadingProfileImageForUserID:(NSString *)userID atIndexPath:(NSIndexPath *)indexPath {
    FIRStorage *storage = [FIRStorage storage];
    NSString *imagePath = [NSString stringWithFormat:@"profile_images/%@.jpg", userID];
    FIRStorageReference *pathRef = [storage referenceWithPath:imagePath];
    [pathRef dataWithMaxSize:1 * 1024 * 1024 completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            Message *message = [self.messageService.messages objectAtIndex:indexPath.row];
            message.mainImage = image;
            
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            NSLog(@"%@", error);
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MessagesViewController_MessagesDetailViewController"]) {
        MessagesDetailViewController *messagesDetailViewController = (MessagesDetailViewController *)[segue destinationViewController];
        messagesDetailViewController.message = self.selectedMessage;
    }
}

@end
