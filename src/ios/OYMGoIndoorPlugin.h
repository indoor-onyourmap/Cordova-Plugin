#import <Cordova/CDVPlugin.h>
#import <Goindoor/Goindoor.h>
@import CoreLocation;


@interface OYMGoIndoorPlugin : CDVPlugin <OYMLocationDelegate, CLLocationManagerDelegate> {
    BOOL connected;
    NSString* callbackLocationId;
    NSString* callbackNotificationId;
}

@property OYMGoIndoor *go;
@property CLLocationManager *manager;


- (void)setConfiguration:(CDVInvokedUrlCommand*)command;
- (void)setLocationCallback:(CDVInvokedUrlCommand*)command;
- (void)setNotificationCallback:(CDVInvokedUrlCommand*)command;
- (void)startLocate:(CDVInvokedUrlCommand*)command;
- (void)stopLocate:(CDVInvokedUrlCommand*)command;
- (void)getPlaces:(CDVInvokedUrlCommand*)command;

@end
