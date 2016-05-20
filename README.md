# Goindoor plugin for Apache Cordova [![Build Status](https://travis-ci.org/indoor-onyourmap/Cordova-Plugin.svg?branch=master)](https://travis-ci.org/indoor-onyourmap/Cordova-Plugin)

## Introduction

The Goindoor plugin for Apache Cordova handles the communication to the server and provides easy access to the developer to the data, as well as several addition features, such as location provider, routing, statistics and asset management.
An extensive developer documentation can be found [here](http://indoor-onyourmap.github.io/Cordova-Plugin/).

This plugin is still under beta, and some functions might not be yet implemented.


## Preparing the environment
### Adding plugin
This plugin can be added to your current Cordova application using the following command:

```bash
cordova plugin add cordova-goindoor
```

## Requirements
### Android
- The minimum SDK version that the app targets should be API 18
- It requires Java 7 or higher

### iOS
- The minimum iOS version that the app targets should be iOS7


## Preparing a sample app
In order to use the goindoor plugin, a basic Cordova app that targets Android and/or iOS shall be created. After making all the modifications mentioned in the previous section, it is necessary to bear in mind that the application is using Bluetooth and WiFi/Network connection, hence it is necessary to check that all this features are available.

The first step is to set the module configuration once the application has been successfully loaded and the `deviceready` callback is called. As input it is required to provide the account, password and a callback that will inform whether the module initialization is successful.

```javascript
GoIndoor.setConfiguration("account", "password", aCallback);
```

In order to start the location service, it is required to provide a `onLocationCallback`, `onNotificationCallback` and a `startLocateCallback` to the module. Is in this callback where the user will be notified for the location updates, the triggered notifications and whether the start of the location service has been successful respectively.

```javascript
GoIndoor.startLocate(onLocation, onNotification, aCallback);
```

`onLocation` will provide an LocationResult object with the current latitude, longitude and indoor information (building, floor, etc.) if it is available. `onNotification` will include the notification and place objects that triggered it. `aCallback` will include an NotificationResult object with a flag telling whether the location service starts successfully. Further information of the object structure can be found [here](http://indoor-onyourmap.github.io/Cordova-Plugin/global.html)


### Exiting the app
In order to stop properly the module, it is necessary to call the `stopLocate` method when the module is no longer needed and the location service should be stopped

```javascript
GoIndoor.stopLocate();
```
