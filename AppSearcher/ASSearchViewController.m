//
//  ASSearchViewController.m
//  AppSearcher
//
//  Created by Daniel Hammond on 9/30/12.
//  Copyright (c) 2012 Two Toasters. All rights reserved.
//

#import "ASSearchViewController.h"
#import "AFNetworking.h"
#import <Parse/Parse.h>

NSString * const ReuseIdentifier = @"Cell";

@interface ASSearchViewController () <UISearchBarDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) PFObject *selectedExperiment;
@property (nonatomic, retain) NSDictionary *selectedApplication;

- (float)conversionRateForExperiment:(PFObject*)object;

@end

@implementation ASSearchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ReuseIdentifier];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:(CGRect){0,0,320,44}];
    [searchBar setDelegate:self];
    self.tableView.tableHeaderView = searchBar;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseIdentifier forIndexPath:indexPath];
    NSDictionary *app = [self.results objectAtIndex:indexPath.row];
    cell.textLabel.text = [app valueForKey:@"trackName"];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Would be a really bad idea to block the main thread with a query like this for anything other than a demo/testing
    PFQuery *query = [PFQuery queryWithClassName:@"experiment"];
    NSArray *experiments = [query findObjects];
    // Selecting the most effective experiment 90% of the time and another one at random the other 10%
    // See: http://stevehanov.ca/blog/index.php?id=132
    //
    // First, Select the first experiment
    self.selectedExperiment = [experiments objectAtIndex:0];
    float selectedConversionRate = [self conversionRateForExperiment:self.selectedExperiment];
    // Then, Select the current most effective experiment
    for (PFObject *experiment in experiments) {
        float rate = [self conversionRateForExperiment:experiment];
        if (rate > selectedConversionRate) {
            selectedConversionRate = rate;
            self.selectedExperiment = experiment;
        }
    }
    // 10% of the time choose one of the other experiments
    if (arc4random_uniform(100)>90) {
        NSMutableArray *otherExperiments = [NSMutableArray arrayWithArray:experiments];
        [otherExperiments removeObject:self.selectedExperiment];
        uint randIndex = arc4random_uniform([otherExperiments count]);
        self.selectedExperiment = [otherExperiments objectAtIndex:randIndex];
    }
    // Increment the impression count of the experiment
    int impression = [[self.selectedExperiment valueForKey:@"impressions"] intValue]+1;
    [self.selectedExperiment setValue:[NSNumber numberWithInt:impression] forKey:@"impressions"];
    [self.selectedExperiment save];
    // Button titles
    NSString *buttonTitle = [self.selectedExperiment valueForKey:@"buttonTitle"];
    // Configure alert view
    self.selectedApplication = [self.results objectAtIndex:indexPath.row];
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = [self.selectedApplication valueForKey:@"trackName"];
    alert.message = [self.selectedApplication valueForKey:@"description"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:buttonTitle];
    [alert setDelegate:self];
    [alert show];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    NSString *query = searchBar.text;
    // URL comes from iTunes Affiliate Search API
    // http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html
    NSString *searchURL = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&country=us&entity=software",query];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:searchURL]];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:
                                  ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                      self.results = [JSON valueForKey:@"results"];
                                      [self.tableView reloadData];
                                  }
                                  
                                                                                 failure:
                                  ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                      NSLog(@"failing kind of quietly!");
                                  }];
    [op start];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (1==buttonIndex) {
        // Increment success counter
        int conversions = [[self.selectedExperiment valueForKey:@"conversions"] intValue]+1;
        [self.selectedExperiment setValue:[NSNumber numberWithInt:conversions] forKey:@"conversions"];
        [self.selectedExperiment save];
        // Uncomment this to actually open URL in iTunes (doesn't work on simulator)
        // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self.selectedApplication valueForKey:@"trackViewUrl"]]];
    }
}

- (float)conversionRateForExperiment:(PFObject*)object
{
    return [[object valueForKey:@"conversions"] floatValue] /
    [[object valueForKey:@"impressions"] floatValue];
}

@end
