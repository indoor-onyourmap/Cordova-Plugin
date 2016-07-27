#import "OYMGoIndoorPlugin.h"
#import <Cordova/CDVPlugin.h>

@implementation OYMGoIndoorPlugin

@synthesize go, manager;


- (void)pluginInitialize {
    [super pluginInitialize];

    manager = [CLLocationManager new];
    manager.delegate = self;
}

- (void) didStartSuccessfully {
    NSLog(@"didStartSuccessfully");
}

- (void) didFailStarting {
    NSLog(@"didFailStarting");
    [manager requestAlwaysAuthorization];
}

- (void) onLocation:(OYMLocationResult*)location {
    NSLog(@"onLocation");
    if (callbackLocationId != nil) {
        NSLog(@"callbackLocationId is not nil");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{
                                                                                                                    @"latitude": @(location.latitude),
                                                                                                                    @"longitude": @(location.longitude),
                                                                                                                    @"used": @(location.used),
                                                                                                                    @"accuracy": @(location.accuracy),
                                                                                                                    @"found": location.found,
                                                                                                                    @"floor": location.floor,
                                                                                                                    @"floorNumber": @(location.floorNumber),
                                                                                                                    @"type": @(location.type),
                                                                                                                    @"buildingName": location.buildingName,
                                                                                                                    @"building": location.building,
                                                                                                                    @"geofences": @(location.geofences)
                                                                                                                    }];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackLocationId];
    } else {
        NSLog(@"callbackLocationId is nil");
    }
}

- (void) onNotification:(OYMNotificationResult*)notification {
    NSLog(@"onNotification");
    if (callbackNotificationId != nil) {
        NSLog(@"callbackNotificationId is not nil");
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{
                                                                                                                    @"notification": [notification.notification toJson],
                                                                                                                    @"place": [notification.place toJson]                                                                                                                   }];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackNotificationId];
    } else {
        NSLog(@"callbackNotificationId is nil");
    }
}

- (void) locationAlwaysAuthorizationRequired:(CLAuthorizationStatus)current {
    NSLog(@"locationAlwaysAuthorizationRequired");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusAuthorizedAlways) {
        [manager requestAlwaysAuthorization];
    }
}


- (void)setConfiguration:(CDVInvokedUrlCommand*)command {
    go = [OYMGoIndoor goIndoorWithBlock:^(id<GoIndoorBuilder> builder) {
        [builder setAccount:[command.arguments objectAtIndex:0]];
        [builder setPassword:[command.arguments objectAtIndex:1]];
        NSDictionary* opts = [command.arguments objectAtIndex:2];
        if (!(opts == nil || [opts isKindOfClass:[NSNull class]])) {
            if ([opts objectForKey:@"locationType"] && [[opts objectForKey:@"locationType"] isKindOfClass:[NSNumber class]]) {
                [builder setLocationType:[[opts objectForKey:@"locationType"] intValue]];
            }
            if ([opts objectForKey:@"locationUpdate"] && [[opts objectForKey:@"locationType"] isKindOfClass:[NSNumber class]]) {
                [builder setLocationUpdate:[[opts objectForKey:@"locationUpdate"] longValue]];
            }
            if ([opts objectForKey:@"debug"] && [[opts objectForKey:@"locationType"] isKindOfClass:[NSNumber class]]) {
                [builder setDebug:[[opts objectForKey:@"debug"] boolValue]];
            }
            if ([opts objectForKey:@"updatePolicy"] && [[opts objectForKey:@"locationType"] isKindOfClass:[NSNumber class]]) {
                [builder setUpdatePolicy:[[opts objectForKey:@"updatePolicy"] intValue]];
            }
            if ([opts objectForKey:@"updateTime"] && [[opts objectForKey:@"locationType"] isKindOfClass:[NSNumber class]]) {
                [builder setDatabaseUpdate:[[opts objectForKey:@"updateTime"] longValue]];
            }
        }
        [builder setConnectCallBack:^(BOOL succeed, NSString *message) {
            connected = succeed;
            CDVPluginResult* pluginResult = succeed? [CDVPluginResult resultWithStatus:CDVCommandStatus_OK]: [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

- (void)setLocationCallback:(CDVInvokedUrlCommand*)command {
    callbackLocationId = command.callbackId;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackLocationId];
}

- (void)setNotificationCallback:(CDVInvokedUrlCommand*)command {
    callbackNotificationId = command.callbackId;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackNotificationId];
}

- (void)startLocate:(CDVInvokedUrlCommand *)command {
    CDVPluginResult* pluginResult;
    if (go == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not configured"];
    } else if (connected) {
        [go startLocate:self];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Not connected"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopLocate:(CDVInvokedUrlCommand *)command {
    if (go != nil) {
        [go startLocate:self];
    }
}

- (void)getPlaces:(CDVInvokedUrlCommand*)command {
    NSArray<OYMPlace*>* places;

    NSDictionary* opts = [command.arguments objectAtIndex:0];
    if (!(opts == nil || [opts isKindOfClass:[NSNull class]])) {
        if ([opts objectForKey:@"id"]) {
            if ([opts objectForKey:@"tags"] || [opts objectForKey:@"filter"]) {
                places = [go getPlacesWithId:[opts objectForKey:@"id"] andTags:[opts objectForKey:@"tags"] andFilter:[opts objectForKey:@"filter"]];
            } else {
                places = [go getPlace:[opts objectForKey:@"id"]];
            }
        } else if ([opts objectForKey:@"ids"]) {
            places = [go getPlaces:[opts objectForKey:@"ids"]];
        } else if ([opts objectForKey:@"location"] && [opts objectForKey:@"radius"]) {
            places = [go getPlacesWithLocationResult:[[OYMLocationResult alloc] initWithJson:[opts objectForKey:@"location"]] andRadius:[[opts objectForKey:@"radius"] intValue] andTags:[opts objectForKey:@"tags"] andFilter:[opts objectForKey:@"filter"]];
        } else if ([opts objectForKey:@"latitude"] && [opts objectForKey:@"longitude"] && [opts objectForKey:@"radius"] && [opts objectForKey:@"floorNumber"] && [opts objectForKey:@"building"]) {
            places = [go getPlacesWithLatitude:[[opts objectForKey:@"latitude"] doubleValue] andLongitude:[[opts objectForKey:@"longitude"] doubleValue] andRadius:[[opts objectForKey:@"radius"] intValue] andFloorNumber:[[opts objectForKey:@"floorNumber"] intValue] andBuilding:[opts objectForKey:@"building"] andTags:[opts objectForKey:@"tags"] andFilter:[opts objectForKey:@"filter"]];
        }
    } else {
        places = [go getPlaces];
    }

    NSMutableArray* objs = [NSMutableArray new];
    for (OYMPlace* p in places) {
        [objs addObject: [p toDictionary]];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:objs];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)computeRoute:(CDVInvokedUrlCommand *)command {
    OYMRoutePoint* start = [[OYMRoutePoint alloc] initWithJson:JsonObjectToJsonString([command.arguments objectAtIndex:0])];
    OYMRoutePoint* destination = [[OYMRoutePoint alloc] initWithJson:JsonObjectToJsonString([command.arguments objectAtIndex:1])];
    OYMRoute* route = [go computeRouteFrom:start to:destination];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:route.toDictionary];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


@end
