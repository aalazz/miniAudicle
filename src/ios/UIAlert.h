//
//  UIAlert.h
//  miniAudicle
//
//  Created by Spencer Salazar on 8/5/14.
//
//

#import <Foundation/Foundation.h>

void UIAlertMessage(NSString *message, void (^okHandler)());
void UIAlertMessage2(NSString *message,
                     NSString *button1, void (^button1Handler)(),
                     NSString *button2, void (^button2Handler)());
