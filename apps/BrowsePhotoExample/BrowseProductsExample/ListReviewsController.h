//
//  ListReviewsController.h
//  RateAndReviewExample
//
//  Created by Bazaarvoice Engineering on 4/23/12.
//  Copyright (c) 2012 BazaarVoice. All rights reserved.
//
//  UIViewController for displaying a list of products for a given search
//  term.

#import <UIKit/UIKit.h>
#import "BVIncludes.h"

@interface ListReviewsController : UITableViewController<BVDelegate>

// Array of product data -- this is the data source for the display
@property (strong) NSArray *productData;
// Query term for products  
@property (strong) NSString *searchTerm;

@end