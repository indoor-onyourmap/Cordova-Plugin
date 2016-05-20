import android.util.Log;
import android.widget.Toast;

import com.oym.indoor.ConnectCallback;
import com.oym.indoor.GoIndoor;
import com.oym.indoor.LocationBroadcast;
import com.oym.indoor.LocationResult;
import com.oym.indoor.NotificationResult;
import com.oym.indoor.Place;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.codehaus.jackson.map.ObjectMapper;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.concurrent.TimeUnit;


public class GoIndoorPlugin extends CordovaPlugin {

  public static final String TAG = "Cool Plugin";

  public GoIndoor go;
  private boolean connected = false;

  public CallbackContext callbackConnect;
  public CallbackContext callbackLocation;
  public CallbackContext callbackNotification;

  private ObjectMapper mapper = new ObjectMapper();

  /**
   * Constructor.
   */
  public GoIndoorPlugin() {}

  /**
   * Sets the context of the Command. This can then be used to do things like
   * get file paths associated with the Activity.
   *
   * @param cordova The context of the main Activity.
   * @param webView The CordovaWebView Cordova is running in.
   */

  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    Log.v(TAG,"Init GoIndoorPlugin");
  }

  public boolean execute(final String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

    switch(action) {
      case "setConfiguration":
        callbackConnect = callbackContext;
        try {
          GoIndoor.Builder builder = new GoIndoor.Builder()
                  .setContext(cordova.getActivity().getApplicationContext())
                  .setAccount(args.getString(0))
                  .setPassword(args.getString(1))
                  .setConnectCallback(callback);

          JSONObject opts = args.optJSONObject(2);
          if (opts != null) {
            //noinspection ResourceType
            builder.setLocationType(opts.optInt("locationType", GoIndoor.LOCATION_TYPE_AVERAGE))
            .setLocationUpdate(opts.optLong("locationUpdate", GoIndoor.DEFAULT_LOCATION_REFRESH))
            .setDebug(opts.optBoolean("debug", false))
            .setUpdatePolicy(opts.optInt("updatePolicy", GoIndoor.UPDATE_WIFI | GoIndoor.UPDATE_MOBILE))
            .setDatabaseUpdate(opts.optLong("updateTime", TimeUnit.MINUTES.toMillis(15)));
          }

          go = builder.build();
        } catch (Exception exc) {
          PluginResult result = new PluginResult(PluginResult.Status.ERROR);
          callbackConnect.sendPluginResult(result);
        }
        return true;
      case "setLocationCallback":
        callbackLocation = callbackContext;
        PluginResult r = new PluginResult(PluginResult.Status.ERROR);
        r.setKeepCallback(true);
        callbackContext.sendPluginResult(r);
        return true;
      case "setNotificationCallback":
        callbackNotification = callbackContext;
        PluginResult re = new PluginResult(PluginResult.Status.ERROR);
        re.setKeepCallback(true);
        callbackContext.sendPluginResult(re);
        return true;
      case "startLocate":
        PluginResult res;
        if (go == null) {
          res = new PluginResult(PluginResult.Status.ERROR, "Not configured");
        } else if (connected) {
          go.startLocate(br);
          res = new PluginResult(PluginResult.Status.OK);
        } else {
          res = new PluginResult(PluginResult.Status.ERROR, "Not connected");
        }
        callbackContext.sendPluginResult(res);
        return true;
      case "stopLocate":
        if (go != null) {
          go.stopLocate();
        }
        return true;
      case "getPlaces":
        PluginResult result = null;
        try {
          ArrayList<Place> places = new ArrayList<>();
          JSONObject opts = args.optJSONObject(0);
          if (opts != null) {
            ArrayList<String> tags = null;
            HashMap<String,String> filter = null;
            if (opts.optJSONArray("tags") != null) {
              tags = new ArrayList<>();
              for (int i = 0; i < opts.getJSONArray("tags").length(); i++) {
                tags.add(opts.getJSONArray("tags").getString(i));
              }
            }
            if (opts.optJSONObject("filter") != null) {
              filter = new HashMap<>();
              JSONObject obj = opts.getJSONObject("filter");
              Iterator<String> itr = obj.keys();
              while (itr.hasNext()) {
                String key = itr.next();
                filter.put(key, obj.getString(key));
              }
            }

            if (opts.has("id")) {
              places = go.getPlaces(opts.getString("id"));
            } else if (opts.has("ids")) {
              ArrayList<String> ids = new ArrayList<>();
              for (int i = 0; i < opts.getJSONArray("ids").length(); i++) {
                ids.add(opts.getJSONArray("ids").getString(i));
              }
              places = go.getPlaces(ids);
            } else if (opts.has("location") && opts.has("radius")) {
              places = go.getPlaces(mapper.readValue(opts.getString("location"),LocationResult.class), opts.getInt("radius"), tags, filter);
            } else if (opts.has("latitude") && opts.has("longitude") && opts.has("radius") && opts.has("floorNumber") && opts.has("building")) {
              places = go.getPlaces(opts.getDouble("latitude"), opts.getDouble("longitude"), opts.getInt("radius"), opts.getInt("floorNumber"), opts.getString("building"), tags, filter);
            }
          }

          result = new PluginResult(PluginResult.Status.OK, new JSONArray(mapper.writeValueAsString(places)));
        } catch (Exception e) {
          Log.e("JC", "Exception", e);
          result = new PluginResult(PluginResult.Status.ERROR);
        } finally {
          callbackContext.sendPluginResult(result);
        }
        return true;
      default:
        return false;
    }
  }

  private ConnectCallback callback = new ConnectCallback() {
    @Override
    public void onConnected() {
      Log.i("JC", "Start");
      connected = true;
      PluginResult result = new PluginResult(PluginResult.Status.OK);
      callbackConnect.sendPluginResult(result);

      //go.startLocate(br);
    }

    @Override
    public void onConnectFailure(Exception exc) {
      Log.e("JC", "Exception", exc);
      connected = false;
      PluginResult result = new PluginResult(PluginResult.Status.ERROR);
      callbackConnect.sendPluginResult(result);
    }
  };

  LocationBroadcast br = new LocationBroadcast() {
    @Override
    public void onLocation(LocationResult location) {
      if(callbackLocation != null) {
        Log.i("JC", "callbackLocation is not null");
        try {
          String json = mapper.writeValueAsString(location);
          JSONObject obj = new JSONObject(json);
          PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
          result.setKeepCallback(true);
          callbackLocation.sendPluginResult(result);

        } catch (Exception e) {
          Log.e(TAG, e.toString());
        }
      } else {
        Log.i("JC", "callbackLocation is null");
      }
    }

    @Override
    public void onNotification(NotificationResult notification) {
      if(callbackNotification != null) {
        Log.i("JC", "callbackNotification is not null");
        try {
          String json = mapper.writeValueAsString(notification);
          JSONObject obj = new JSONObject(json);
          PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
          result.setKeepCallback(true);
          callbackNotification.sendPluginResult(result);

        } catch (Exception e) {
          Log.e(TAG, e.toString());
        }
      } else {
        Log.i("JC", "callbackNotification is null");
      }
    }
  };


}
