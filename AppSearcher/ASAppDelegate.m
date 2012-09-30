//
//  ASAppDelegate.m
//  AppSearcher
//
//  Created by Daniel Hammond on 9/30/12.
//  Copyright (c) 2012 Two Toasters. All rights reserved.
//
//  Created as a demo as part of a talk at NC Dev Con
//  You will need to create an app at parse in order to run the demo or make changes, see README or http://parse.com

#import "ASAppDelegate.h"
#import "ASSearchViewController.h"
#import <Parse/Parse.h>

@implementation ASAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    #warning You will need to create a free parse application at http://parse.com and add the parse application id and client keys here
    [Parse setApplicationId:nil clientKey:nil];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[ASSearchViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
