//
//  BVSampleAppResultsViewController.h
//  BVSampleApp
//
//  Created by Bazaarvoice Engineering on 3/10/12.
//  Copyright (c) 2012 Bazaarvoice Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BVSampleAppResultsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *urlTextView;
@property (weak, nonatomic) IBOutlet UITextView *urlResultsView;
@property (strong, nonatomic) NSDictionary *responseToDisplay;
@property (strong, nonatomic) id requestToSend;


@end