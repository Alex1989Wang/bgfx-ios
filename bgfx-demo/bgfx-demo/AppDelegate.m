//
//  AppDelegate.m
//  bgfx-demo
//
//  Created by 王江 on 2020/10/24.
//

#import "AppDelegate.h"
#import "BHomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _appWindow = window;
    BHomeViewController *homeVC = [[BHomeViewController alloc] init];
    window.rootViewController = homeVC;
    [window makeKeyAndVisible];
    return YES;
}

@end
