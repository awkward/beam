//
//  SubredditsTableView.m
//  Beam
//
//  Created by Rens Verhoeven on 29-01-16.
//  Copyright © 2016 Awkward. All rights reserved.
//

#import "SubredditsTableView.h"

@implementation SubredditsTableView

- (void)setContentInset:(UIEdgeInsets)contentInset {
    if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        //Ignore the extreme insets that are caused by the UIKeyboard. The bottom inset should be max 49pt, the height of a UITabBar
        if(contentInset.bottom <= 49 && contentInset.bottom >= -49) {
            [super setContentInset:contentInset];
        }
    }
}

@end
