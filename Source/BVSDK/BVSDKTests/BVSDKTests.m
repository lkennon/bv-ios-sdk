//
//  BVSDKTests.m
//  BVSDKTests
//
//  Created by Bazaarvoice Engineering on 11/26/12.
//  Copyright (c) 2012 Bazaarvoice Inc. All rights reserved.
//

#import "BVSDKTests.h"
#import "BVGet.h"
#import "BVPost.h"
#import "BVMediaPost.h"
#import "BVSettings.h"
#import "BVNetwork.h"

@implementation BVSDKTests
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    requestComplete = NO;
    [BVSettings instance].staging = YES;
    [BVSettings instance].baseURL = @"reviews.apitestcustomer.bazaarvoice.com";
    [BVSettings instance].passKey = @"2cpdrhohmgmwfz8vqyo48f52g";
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



- (void)checkParams:(NSMutableDictionary *)params {
    NSString *url = [sentRequest performSelector:@selector(requestURL)];
    NSDictionary *baseDictionary = [NSDictionary
                                    dictionaryWithObjectsAndKeys:BV_API_VERSION,
                                    @"ApiVersion",
                                    [BVSettings instance].passKey,
                                    @"PassKey",
                                    nil];
    [params addEntriesFromDictionary:baseDictionary];
    NSMutableDictionary *foundParams = [[NSMutableDictionary alloc] init];
    NSArray *comp1 = [url componentsSeparatedByString:@"?"];
    NSString *query = [comp1 lastObject];
    NSArray *queryElements = [query componentsSeparatedByString:@"&"];
    for (NSString *element in queryElements) {
        NSArray *keyVal = [element componentsSeparatedByString:@"="];
        NSAssert(keyVal.count == 2, @"Malformed URL");
        [foundParams setObject:[keyVal objectAtIndex:1] forKey:[keyVal objectAtIndex:0]];
    }
    
    NSAssert(params.count == foundParams.count, @"Wrong number of URL params... %d expected vs %d found\n request:%@", params.count, foundParams.count, url);
    
    NSArray *keyArray = [params allKeys];
    int count = [keyArray count];
    for (int i=0; i < count; i++) {
        NSString * key = [keyArray objectAtIndex:i];
        NSAssert([foundParams objectForKey:key], @"Request missing parameter %@", key);
        NSString *requestVal = (NSString *)[foundParams objectForKey:key];
        NSString *expectedVal = (NSString *)[params objectForKey:key];
        NSAssert([requestVal isEqualToString:expectedVal], @"Request value of %@ does not match expected value of %@", requestVal, expectedVal);
    }
}

- (void)didReceiveResponse:(NSDictionary *)response forRequest:(id)request{
    
    //NSLog(@"%@", response);
    requestComplete = YES;
    receivedResponse = response;
    sentRequest = request;
    
    BOOL hasErrors = [[response objectForKey:@"HasErrors"] boolValue] || ([response objectForKey:@"HasErrors"] == nil);
    if (hasErrors) {
        NSLog(@"\n\n==========================\n\n");
        STFail(@"Error in Class: %@ \n Failure: %@", [request class], [response objectForKey:@"Errors"]);
        NSLog(@"\n\n==========================\n\n");
        NSLog(@"%@", response);
    }
    else if(!receivedProgressCallback && [request isKindOfClass:[BVPost class]])
    {
        // We only need to check if we received a progress callback for POST / submission requests
        NSLog(@"\n\n==========================\n\n");
        STFail(@"Failed to receive a progress callback for request: %@", [request class]);
        NSLog(@"\n\n==========================\n\n");
    }
    else
    {
        STAssertNotNil(response, @"Invalid response for Class: %@", [request class]);
    }
    NSLog(@"\n\n");
}

- (void)didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite forRequest:(id)request{
    receivedProgressCallback = YES;
}

- (void)didFailToReceiveResponse:(NSError *)err forRequest:(id)request {
    requestComplete = YES;
}

- (void)testShowReviewSparse {
    BVGet *request = [[BVGet alloc] init];
    [request sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}


- (void)testShowReview {
    BVGet *showDisplayRequest = [[ BVGet alloc ] initWithType:BVGetTypeReviews];
    [ showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"6601211"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"009"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 50;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    showDisplayRequest.search = @"Great sound";
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:009", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"Id:eq:6601211", @"Filter", @"50", @"Limit", @"Great%20sound", @"Search", nil]];
}


- (void)testShowReviewIncludesSearch {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeReviews];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest setSearchOnIncludedType:BVIncludeTypeProducts search:@"Increase your potential to shine"];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Id:asc", @"Sort_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"Increase%20your%20potential%20to%20shine", @"Search_Products", nil]];
}


- (void)testShowQuestionSparse {
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeQuestions];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (void)testShowQuestion {
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeQuestions];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"87757"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"test1"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 50;
    showDisplayRequest.excludeFamily = true;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:test1", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"Id:eq:87757", @"Filter", @"50", @"Limit", @"true", @"ExcludeFamily", nil]];
    
    
}

- (void)testShowQuestionsSparse {
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeQuestions];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}


- (void)testShowQuestions{
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeQuestions];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"6055"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"test0"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 50;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeAnswers];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Answers", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:test0", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"Id:eq:6055", @"Filter", @"50", @"Limit", nil]];
}

- (void)testShowStorySparse {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStories];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"14181"];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Id:eq:14181", @"Filter",nil]];
}

- (void)testShowStory {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStories];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"14181"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeComments forAttribute:@"Id" equality:BVEqualityEqualTo value:@"1010"];
    [showDisplayRequest addInclude:BVIncludeTypeComments];
    showDisplayRequest.limit = 50;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeComments value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeComments attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeStories];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Stories", @"Stats", @"Id:asc", @"Sort_Comments", @"Id:eq:1010", @"Filter_Comments", @"10", @"Limit_Comments", @"Id:asc", @"Sort", @"Comments", @"Include", @"0", @"Offset", @"Id:eq:14181", @"Filter", @"50", @"Limit", nil]];
}


- (void)testShowCommentsSparse {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeReviewCommments];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (void)testShowComments {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeReviewCommments];
    [showDisplayRequest setFilterForAttribute:@"ReviewId" equality:BVEqualityEqualTo value:@"6597809"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"2323001"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 50;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:2323001", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"ReviewId:eq:6597809", @"Filter", @"50", @"Limit", nil]];
}

- (void)testShowCommentStorySparse {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStoryCommments];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
    
}

- (void)testShowCommentStory {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStoryCommments];
    [showDisplayRequest setFilterForAttribute:@"StoryId" equality:BVEqualityEqualTo value:@"967"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"test1"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 10;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:test1", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"StoryId:eq:967", @"Filter", @"10", @"Limit", nil]];
}

- (void)testShowProfileSparse {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeAuthors];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (void)testShowProfile {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeAuthors];
    [showDisplayRequest setFilterForAttribute:@"TotalCommentCount" equality:BVEqualityGreaterThanOrEqual value:@"0"];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"smartPP"];
    showDisplayRequest.limit = 10;
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort",  @"0", @"Offset", @"Id:eq:smartPP", @"Filter", @"10", @"Limit", nil]];
}

- (void)testShowProductsSparse {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeProducts];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (void)testShowProducts {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeProducts];
    [showDisplayRequest setFilterForAttribute:@"CategoryId" equality:BVEqualityEqualTo value:@"testcategory1011"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeReviews forAttribute:@"Id" equality:BVEqualityEqualTo value:@"83501"];
    [showDisplayRequest addInclude:BVIncludeTypeReviews];
    showDisplayRequest.limit = 10;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeReviews value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeReviews attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Reviews", @"Id:eq:83501", @"Filter_Reviews", @"10", @"Limit_Reviews", @"Id:asc", @"Sort", @"Reviews", @"Include", @"0", @"Offset", @"CategoryId:eq:testcategory1011", @"Filter", @"10", @"Limit", nil]];
}

- (void)testShowCateogrySparse {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeCategories];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:nil]];
}

- (void)testShowCateogry {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeCategories];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"testCategory1011"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"test2"];
    [showDisplayRequest addInclude:BVIncludeTypeProducts];
    showDisplayRequest.limit = 10;
    [showDisplayRequest setLimitOnIncludedType:BVIncludeTypeProducts value:10];
    showDisplayRequest.offset = 0;
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest addSortOnIncludedType:BVIncludeTypeProducts attribute:@"Id" ascending:YES];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"Reviews", @"Stats", @"Id:asc", @"Sort_Products", @"Id:eq:test2", @"Filter_Products", @"10", @"Limit_Products", @"Id:asc", @"Sort", @"Products", @"Include", @"0", @"Offset", @"Id:eq:testCategory1011", @"Filter", @"10", @"Limit", nil]];
}

- (void)testShowStatistics {
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStatistics];
    [showDisplayRequest setFilterForAttribute:@"ProductId" equality:BVEqualityEqualTo values:[NSArray arrayWithObjects:@"test1", @"test2", @"test3", nil]];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeNativeReviews];
    
    [showDisplayRequest sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    [self checkParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                       @"ProductId:eq:test1,test2,test3", @"Filter", @"Reviews,NativeReviews", @"Stats", nil]];
    
}



- (void)testSubmissionReview
{
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeReview];
    request.productId = @"100003401";
    request.userId = @"123abcd";
    request.rating = 5;
    request.title = @"Test title";
    request.reviewText = @"Some kind of review text.";
    request.userNickname = @"testnickname";
    [request addPhotoUrl:@"http://apitestcustomer.ugc.bazaarvoice.com/bvstaging/5555/ps_amazon_s3_3rgg6s4xvev0zhzbnabyneo21/photo.jpg" withCaption:nil];
    [request addVideoUrl:@"http://www.youtube.com" withCaption:nil];
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionReviewBackgroundThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BVPost *request = [[BVPost alloc] initWithType:BVPostTypeReview];
        request.productId = @"100003401";
        request.userId = @"123abcd";
        request.rating = 5;
        request.title = @"Test title";
        request.reviewText = @"Some kind of review text.";
        request.userNickname = @"testnickname";
        [request addPhotoUrl:@"http://apitestcustomer.ugc.bazaarvoice.com/bvstaging/5555/ps_amazon_s3_3rgg6s4xvev0zhzbnabyneo21/photo.jpg" withCaption:nil];
        [request addVideoUrl:@"http://www.youtube.com" withCaption:nil];
        
        [request sendRequestWithDelegate:self];
    });
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionQuestions {
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeQuestion];
    request.categoryId = @"1020";
    request.locale = @"en_US";
    request.userId = @"123abcd";
    request.questionSummary =  @"Some kind of question";
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionAnswers {
    [BVSettings instance].baseURL = @"answers.apitestcustomer.bazaarvoice.com";
    
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeAnswer];
    request.questionId = @"6104";
    request.userId = @"123abcd";
    request.questionSummary =  @"Some kind of answer";
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionStories {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeStory];
    request.title = @"This is the title";
    request.storyText = @"This is my story";
    request.categoryId = @"1020235";
    request.userId = @"123abc";
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionReviewComments {
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeReviewComment];
    request.commentText = @"This is my comment text";
    request.reviewId = @"83964";
    request.userId = @"123abc";
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionStoryComments {
    [BVSettings instance].baseURL = @"stories.apitestcustomer.bazaarvoice.com";
    BVPost *request = [[BVPost alloc] initWithType:BVPostTypeStoryComment];
    request.commentText = @"This is my comment text";
    request.storyId = @"967";
    request.userId = @"123abc";
    
    [request sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}


- (void)testSubmissionVideos {
    
    /*
     requestComplete = NO;
     receivedProgressCallback = NO;
     BVSubmissionVideo *mySubmission = [[BVSubmissionVideo alloc] init];
     mySubmission.parameters.contentType = @"review";
     mySubmission.parameters.video = @"http://www.youtube.com/";
     mySubmission.parameters.userId = @"123abc";
     mySubmission.delegate = self;
     
     [mySubmission startAsynchRequest];
     NSRunLoop *theRL = [NSRunLoop currentRunLoop];
     // Begin a run loop terminated when the requestComplete it set to true
     while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
     
     */
}




- (void)testSubmissionPhotos {
    
    BVMediaPost *mySubmission = [[BVMediaPost alloc] initWithType:BVMediaPostTypePhoto];
    mySubmission.contentType = BVMediaPostContentTypeReview;
    mySubmission.userId = @"123";
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [bundle pathForResource:@"bv533x533" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    mySubmission.photo = image;
    
    [mySubmission sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionPhotosRotated {
    
    BVMediaPost *mySubmission = [[BVMediaPost alloc] initWithType:BVMediaPostTypePhoto];
    mySubmission.contentType = BVMediaPostContentTypeReview;
    mySubmission.userId = @"123";
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [bundle pathForResource:@"270cw" ofType:@"JPG"];
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    mySubmission.photo = image;
    
    [mySubmission sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    // Check image manually
    NSLog(@"%@", receivedResponse);
    
}

- (void)testSubmissionPhotoURL {
    
    BVMediaPost *mySubmission = [[BVMediaPost alloc] initWithType:BVMediaPostTypePhoto];
    mySubmission.contentType = BVMediaPostContentTypeReview;
    mySubmission.userId = @"123";
    mySubmission.photoUrl = @"http://dogr.io/doge.png";
    
    [mySubmission sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)testSubmissionVideo {
    
    BVMediaPost *mySubmission = [[BVMediaPost alloc] initWithType:BVMediaPostTypeVideo];
    mySubmission.contentType = BVMediaPostContentTypeReview;
    mySubmission.userId = @"123";
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *videoPath = [bundle pathForResource:@"sample_mpeg4" ofType:@"mp4"];
    NSData *video = [NSData dataWithContentsOfFile:videoPath];
    [mySubmission setVideo:video withFormat:BVVideoFormatTypeMP4];
    [mySubmission sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
    // Check video manually
    NSLog(@"%@", receivedResponse);
}



- (void)testSubmissionFeedback {
    BVPost *mySubmission = [[BVPost alloc] initWithType:BVPostTypeFeedback];
    mySubmission.contentType = BVFeedbackContentTypeReview;
    mySubmission.contentId = @"83964";
    mySubmission.userId = @"123abc";
    mySubmission.feedbackType = BVFeedbackTypeHelpfulness;
    mySubmission.vote = BVFeedbackVoteTypeNegative;
    [mySubmission sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    
}

- (void)testSubmissionFeedback2 {
    BVPost *mySubmission = [[BVPost alloc] initWithType:BVPostTypeFeedback];
    mySubmission.contentType = BVFeedbackContentTypeReview;
    mySubmission.contentId = @"83964";
    mySubmission.userId = @"123abc";
    mySubmission.feedbackType = BVFeedbackTypeInappropriate;
    mySubmission.reasonText = @"This post was not nice.";    [mySubmission sendRequestWithDelegate:self];
    [mySubmission sendRequestWithDelegate:self];
    
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}


- (void)testParamsAttached {
    BVPost *mySubmission = [[BVPost alloc] initWithType:BVPostTypeReview];
    mySubmission.productId = @"10000sadfgasdg3401";
    mySubmission.userId = @"WHEEEEMYNAMEISSAME";
    mySubmission.rating = 5;
    mySubmission.title = @"Test title";
    mySubmission.reviewText = @"Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text. Some kind of review text.";
    mySubmission.userNickname = @"testnickname4";
    [mySubmission addPhotoUrl:@"http://apitestcustomer.ugc.bazaarvoice.com/bvstaging/5555/ps_amazon_s3_3rgg6s4xvev0zhzbnabyneo21/photo.jpg" withCaption:nil];
    [mySubmission addPhotoUrl:@"http://apitestcustomer.ugc.bazaarvoice.com/bvstaging/5555/ps_amazon_s3_a11b8t4wlgb914fjaiudaadvo/photo.jpg" withCaption:@"This photo is cool!"];
    [mySubmission addPhotoUrl:@"http://apitestcustomer.ugc.bazaarvoice.com/bvstaging/5555/ps_amazon_s3_5ugnhmmq24p1q35tlygrqalz9/photo.jpg" withCaption:nil];
    [mySubmission addTagForDimensionExternalId:@"Pro" value:@"fit"];
    [mySubmission addTagForDimensionExternalId:@"Pro" value:@"comfortable fit"];
    [mySubmission addTagIdForDimensionExternalId:@"Pro/ProService" value:true];
    [mySubmission addTagIdForDimensionExternalId:@"Con/ConFitness" value:true];
    
    [mySubmission sendRequestWithDelegate:self];
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];
    // Begin a run loop terminated when the requestComplete it set to true
    while (!requestComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

@end
