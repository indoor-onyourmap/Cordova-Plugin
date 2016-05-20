/**
* @fileOverview
* @author Joan Comellas
* @version 0.1
* @license Apache-2.0
*/


var exec = require('cordova/exec');


/**
*  GoIndoor module object.
*
* @namespace
*/
function GoIndoor() {
 console.log("GoIndoor.js: Created");
}

GoIndoor.prototype = {
  /**
  *  Enumeration defining the possible algorithms to be used.
  *
  * @constant
  * @readonly
  * @enum {number}
  */
  LocationAlgorithm: {
      /** Weighted average */
      LOCATION_TYPE_AVERAGE: 0,
      /** Closest Beacon */
      LOCATION_TYPE_CLOSEST: 1,
      /** Weighted average with projection to the closest edge */
      LOCATION_TYPE_PROJECT: 2
  },

  /**
  *  Enumeration defining the database update policy.
  *
  * @constant
  * @readonly
  * @enum {number}
  */
  UpdatePolicy: {
      /** Updates are disabled */
      UPDATE_NO: 0,
      /** Update only over Wifi */
      UPDATE_WIFI: 1,
      /** Update only over Mobile data connection */
      UPDATE_MOBILE: 1<<1
  }
};

/**
*  This callback will handle the configuration process.
*
* @callback GoIndoor~setConfigurationCallback
* @param {boolean} flag - Flag to know whether the set configuration succeed
*/

/**
* @typedef {object} ConfigurationOptions
* @property {GoIndoor.LocationAlgorithm} [locationType] - Positioning type
* @property {number} [locationUpdate] - Update rate in msec
* @property {boolean} [debug] - Debug mode
* @property {GoIndoor.UpdatePolicy} [updatePolicy] - Update policy
* @property {number} [updateTime] - Database update time in msec
*/

/**
*  This function will set all the required configuration to start the GoIndoor module.
*
* @param {!string} account - Account
* @param {!string} password - Password
* @param {!GoIndoor~setConfigurationCallback} callback - Callback to handle the process
* @param {ConfigurationOptions=} opts - Advanced configuration options
*/
GoIndoor.prototype.setConfiguration = function (account, password, callback, opts) {
  exec(this.setConfigurationInnerCallback(true, callback), this.setConfigurationInnerCallback(false, callback), "GoIndoor", "setConfiguration",[account, password, opts]);
};

/**
* @private
*/
GoIndoor.prototype.setConfigurationInnerCallback = function (flag, callback) {
  return function() {
    callback(flag);
  }
};

/**
*  This callback will handle the user location.
*
* @callback GoIndoor~onLocationCallback
* @param {LocationResult} location - Object containing the user location
*/
/**
* @typedef {object} LocationResult
* @property {!number} latitude - WGS84 Latitude
* @property {!number} longitude - WGS84 Longitude
* @property {!number} used - Number of Beacons used
* @property {!number} accuracy - Position accuracy (meters)
* @property {number[]} found - List including the longitude, latitude and accuracy of each Beacon in sight
* @property {?string} floor - Floor ID
* @property {number} floorNumber - Floor number
* @property {!number} type - Positioning type
* @property {?string} buildingName - Building name
* @property {?string} building - Building ID
* @property {number} geofences - Number of geofences
*/

/**
*  This callback will handle the triggered notifications.
*
* @callback GoIndoor~onNotificationCallback
* @param {NotificationResult} notificationResult - Object containing the notification and its place
*/
/**
* @typedef {object} NotificationResult
* @property {Notification} notification - Notification triggered
* @property {Place} place - POI related to the Notification
*/
/**
* @typedef {object} Notification
* @property {string} id - Notification unique identifier
* @property {string} building - Parent building unique identifier
* @property {string} floor - Parent floor unique identifier
* @property {number} floorNumber - Parent floor number
* @property {string} place - ID of the poi that will trigger the event
* @property {Object.<string,string>} properties - Keys/values that define the content of the notification
* @property {string} action - Action that will trigger this notification ("ENTER", "STAY", "LEAVE" or "NEARBY")
* @property {number} delay - Delay before triggerring the notification
* @property {number} range - Extended area where the notification will trigger
* @property {number} repeat - Number of seconds when this notification can be repeated again
* @property {Object.<string,Targets>} targets - Keys/values that defines the notification target
*/
/**
* @typedef {object} Place
* @property {string} id - Automatically generated usedProximityUuid
* @property {string} name - Place name
* @property {string} building - Building ID
* @property {string} floor - Floor ID
* @property {number} floorNumber - Floor number
* @property {Geometry} geometry - Place geometry
* @property {number} latitude - WGS84 Latitude
* @property {number} longitude - WGS84 Longitude
* @property {string[]} tags - Tag list
* @property {Object.<string,string>} properties - Properties
*/

/**
*  This callback will handle the start Locate process.
*
* @callback GoIndoor~startLocateCallback
* @param {!object} response - Response object
* @param {!boolean} response.flag - Flag to know whether the location service starts successfully
* @param {?string} response.message - Message with further information of the error. May not be defined.
*/

/**
* This function will start the indoor location.
*
* @param {!GoIndoor~onLocationCallback} onLocation Callback to handle the user location
* @param {!GoIndoor~onNotificationCallback} onNotification Callback to handle the triggered notifications
* @param {!GoIndoor~startLocateCallback} callback Callback to handle the process
*/
GoIndoor.prototype.startLocate = function (onLocation, onNotification, callback) {
  exec(onLocation, setLocationInnerCallback, "GoIndoor", "setLocationCallback",[]);
  function setLocationInnerCallback() {
    exec(onNotification, setNotificationInnerCallback, "GoIndoor", "setNotificationCallback",[]);
  }
  function setNotificationInnerCallback() {
    exec(startLocateInnerCallback(true), startLocateInnerCallback(false), "GoIndoor", "startLocate", []);
  }
  function startLocateInnerCallback(flag) {
    return function(resp) {
      var response = {};
      response.succeed = flag;
      if (resp === "string") {
        response.message = resp;
      }
      callback(response);
    }
  }
};

/**
* This function will start the indoor location.
*/
GoIndoor.prototype.stopLocate = function () {
  exec(null, null, "GoIndoor", "stopLocate", []);
};


/**
*  This callback will handle the get Places process.
*
* @callback GoIndoor~setPlacesCallback
* @param {!object} response - Response object
* @param {boolean} response.flag - Flag to know whether the request succeed
* @param {Place[]} response.data - Place list
*/

/**
*  Options to get places. Possible combinations are:<br/>
* <ul>
* <li> id
* <li> ids
* <li> location, radius, tags^, filter^
* <li> id, tags^, filter^
* <li> latitude, longitude, radius, floorNumber, building, tags^, filter^
* </ul>
* where ^ parameters are optionals
*
* @typedef {object} GetPlacesOptions
* @property {string=} id - Building or floor ID whose places need to be retrieved
* @property {Array.<string>=} ids - Building or floor IDs whose places need to be retrieved
* @property {LocationResult=} location - Location whose places needs to be retrieved
* @property {number=} radius - Radius from the location. If <tt>0</tt> it will returns the closest one. Must be >=0
* @property {number=} latitude - WGS84 Latitude whose places needs to be retrieved
* @property {number=} longitude - WGS84 Longitude whose places needs to be retrieved
* @property {number=} floorNumber - Floor number whose places needs to be retrieved
* @property {string=} building - Building ID whose places needs to be retrieved
* @property {Array.<string>=} tags - List of POI tags that should match in the search
* @property {Object.<string,string>=} filter - Map of POI properties that should match in the search
*/

/**
*  Getter for the place list.
*
* @param {!GoIndoor~setPlacesCallback} callback - Callback to handle the process
* @param {GetPlacesOptions=} opts - Advanced configuration options
*/
GoIndoor.prototype.getPlaces = function (callback, opts) {
  exec(this.getPlacesInnerCallback(true, callback), this.getPlacesInnerCallback(false, callback), "GoIndoor", "getPlaces",[opts]);
};

/**
* @private
*/
GoIndoor.prototype.getPlacesInnerCallback = function (flag, callback) {
  return function(resp) {
    var response = {};
    response.succeed = flag;
    if (flag && Object.prototype.toString.call(resp) === '[object Array]') {
      response.data = [];
      if (resp.length > 0) {
        var conversion = (typeof resp[0] === 'string');
        for (var i = 0; i < resp.length; i++) {
          response.data[i] = conversion? JSON.parse(resp[i]): resp[i];
          if (conversion) {
            response.data[i].geometry = JSON.parse(response.data[i].geometry);
          }
        }
      }
    } else {
      response.data = resp;
    }
    callback(response);
  }
};


 var goIndoor = new GoIndoor();
 module.exports = goIndoor;
