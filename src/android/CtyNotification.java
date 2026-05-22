package cty.cordova.plugin.CtyNotification;


import android.Manifest;
import android.util.Log;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.ParseException;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.content.Intent;
import android.net.Uri;

import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;


public class CtyNotification extends  CordovaPlugin {
    private Context mActContext;
    private static final int REQUEST_CODE_POST_NOTIFICATIONS = 1001;
    private static final long PERMISSION_RESULT_TIMEOUT_MS = 15000L;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private Runnable permissionTimeoutRunnable;
    private String pendingAction;
    private JSONArray pendingArgs;
    private CallbackContext pendingCallbackContext;
    private boolean waitingPermissionFromSettings = false;
    private boolean pausedAfterOpeningSettings = false;

    @Override
     public void initialize(CordovaInterface cordova, CordovaWebView webView){
        super.initialize(cordova,webView);
        mActContext = this.cordova.getActivity().getApplicationContext();
     }    

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        Log.d("CtyNotification", "execute called: action=" + action);
        
        if (args == null || args.length() == 0) {
            Log.e("CtyNotification", "execute: args is empty for action=" + action);
            callbackContext.error("args is empty");
            return true;
        }
        int notificationId =Integer.parseInt(args.getString(0)); //通知的Id
        int permissionStatus = PackageManager.PERMISSION_GRANTED;
        int targetSdk = cordova.getActivity().getApplicationInfo().targetSdkVersion;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && targetSdk >= Build.VERSION_CODES.TIRAMISU) {  // Android 13+ and targetSdk 33+
            permissionStatus = cordova.getActivity().checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS);
            Log.d("CtyNotification", "POST_NOTIFICATIONS permission status: " + (permissionStatus == PackageManager.PERMISSION_GRANTED ? "GRANTED" : "DENIED") + ", targetSdk=" + targetSdk);
        } else {
            Log.d("CtyNotification", "Skipping runtime POST_NOTIFICATIONS request. sdk=" + Build.VERSION.SDK_INT + " targetSdk=" + targetSdk);
        }
        
        if (permissionStatus != PackageManager.PERMISSION_GRANTED) {
            // Request permission
            Log.w("CtyNotification", "POST_NOTIFICATIONS permission not granted, requesting...");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                pendingAction = action;
                pendingArgs = args;
                pendingCallbackContext = callbackContext;
                requestPermissions(callbackContext);
            }
            // Don't continue execution; wait for onRequestPermissionsResult
            return true;
        }

        boolean notificationsEnabled = NotificationManagerCompat.from(cordova.getActivity()).areNotificationsEnabled();
        Log.d("CtyNotification", "NotificationManagerCompat.areNotificationsEnabled=" + notificationsEnabled);
        if (!notificationsEnabled) {
            pendingAction = action;
            pendingArgs = args;
            pendingCallbackContext = callbackContext;
            Log.w("CtyNotification", "Notifications disabled at system/app-ops level, opening settings");
            openNotificationSettingsForManualGrant();
            return true;
        }

        Log.d("CtyNotification", "Permissions already granted, proceeding with action");
        String title =args.getString(1); //标题
        String subText =args.getString(2); //子标题
        String message =args.getString(3); //通知的内容
        String urlLargeIco =args.getString(4); //大图标
        String urlBigImage =args.getString(5); //大图
        String strDate =args.getString(6); //通知时间
        boolean strRepeat =Boolean.parseBoolean(args.getString(7)); //是否重复推送
        String interval =args.getString(8); //通知时间
        String strType =args.getString(9); //通知时间
        int total = args.length() > 10 ? args.optInt(10, 0) : 0; //重复总次数，0=无限

        //初始化
        if (action.equals("commonNotification")) {
            CtyNotificationHelper.CommonNotification(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return true;
        }
        else if (action.equals("largeTextNotification")) {
            CtyNotificationHelper.LargeTextNotification(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return  true;
        }
       else  if (action.equals("importantNotification")) {
            CtyNotificationHelper.ImportantNotification(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return  true;
        }
       else if (action.equals("bigImageNotification")) {
            cordova.getThreadPool().execute(new LoadImageTask(mActContext, notificationId,title,subText,message,urlLargeIco,urlBigImage));
            callbackContext.success("success");
            return  true;
       }
       else if (action.equals("timedNotication")) {
            try {
                if (args.length() < 10) {
                    Log.e("CtyNotification", "timedNotication: insufficient args, expected 10 got " + args.length());
                    callbackContext.error("Missing required arguments for timed notification");
                    return true;
                }
                Log.d("CtyNotification", "timedNotication called: id=" + notificationId + " title=" + title + " strDate=" + strDate + " interval=" + interval + " repeat=" + strRepeat + " strType=" + strType);
                
                if (strDate == null || strDate.isEmpty()) {
                    Log.e("CtyNotification", "timedNotication: strDate is null or empty");
                    callbackContext.error("strDate cannot be empty");
                    return true;
                }
                LocalNotificationScheduler.scheduleLocalNotification(mActContext,notificationId,title,subText,message,urlLargeIco,urlBigImage,strType, strDate,interval,strRepeat,total);
                callbackContext.success("success");
                return  true;
            } catch (ParseException e) {
                callbackContext.error(e.toString());
                throw new RuntimeException(e);
            } catch (java.text.ParseException e) {
                callbackContext.error(e.toString());
                throw new RuntimeException(e);
            }
        }
        else if (action.equals("timedCancelNotication")) {
            try {
                LocalNotificationScheduler.scheduleCancelLocalNotification(mActContext,notificationId);
                callbackContext.success("success");
                return  true;
            } catch (ParseException e) {
                callbackContext.error(e.toString());
                throw new RuntimeException(e);
            } catch (java.text.ParseException e) {
                callbackContext.error(e.toString());
                throw new RuntimeException(e);
            }
        }
        callbackContext.success("error");
        return  false;
    }

    //检测权限
    private boolean checkPermission(String permission) {
        return ContextCompat.checkSelfPermission(mActContext, permission) == PackageManager.PERMISSION_GRANTED;
    }


    private void requestPermissions(CallbackContext callbackContext) {
        int targetSdk = cordova.getActivity().getApplicationInfo().targetSdkVersion;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && targetSdk >= Build.VERSION_CODES.TIRAMISU) {  // Android 13+ and targetSdk 33+
            Log.d("CtyNotification", "Requesting POST_NOTIFICATIONS permission");
            String[] permissions = new String[]{
                    Manifest.permission.POST_NOTIFICATIONS
            };
            cordova.getActivity().runOnUiThread(() ->
                    cordova.requestPermissions(this, REQUEST_CODE_POST_NOTIFICATIONS, permissions)
            );
            // Fallback log/error when some ROMs don't deliver permission callback
            if (permissionTimeoutRunnable != null) {
                mainHandler.removeCallbacks(permissionTimeoutRunnable);
            }
            permissionTimeoutRunnable = () -> {
                if (pendingCallbackContext != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    // Already guiding user in Settings, don't reopen Settings repeatedly.
                    if (waitingPermissionFromSettings) {
                        Log.d("CtyNotification", "Permission timeout ignored because waitingPermissionFromSettings=true");
                        return;
                    }
                    int now = cordova.getActivity().checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS);
                    if (now != PackageManager.PERMISSION_GRANTED) {
                        Log.w("CtyNotification", "Permission request timeout without callback; permission still DENIED");
                        openNotificationSettingsForManualGrant();
                    }
                }
            };
            mainHandler.postDelayed(permissionTimeoutRunnable, PERMISSION_RESULT_TIMEOUT_MS);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Log.d("CtyNotification", "Android runtime does not require POST_NOTIFICATIONS request for current targetSdk");
        }
    }

    private void openNotificationSettingsForManualGrant() {
        try {
            waitingPermissionFromSettings = true;
            pausedAfterOpeningSettings = false;
            String pkg = cordova.getActivity().getPackageName();

            // Some ROMs show disabled/grey controls on notification sub-page.
            // App details page is more reliable because users can enter Permissions -> Notifications.
            Intent detailsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.fromParts("package", pkg, null));

            if (detailsIntent.resolveActivity(cordova.getActivity().getPackageManager()) != null) {
                cordova.getActivity().startActivity(detailsIntent);
                Log.w("CtyNotification", "Opened app details settings for manual permission grant: package=" + pkg);
            } else {
                Intent notificationIntent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, pkg);
                cordova.getActivity().startActivity(notificationIntent);
                Log.w("CtyNotification", "Fallback opened app notification settings for manual permission grant: package=" + pkg);
            }
        } catch (Exception e) {
            Log.e("CtyNotification", "Failed to open notification settings", e);
            if (pendingCallbackContext != null) {
                pendingCallbackContext.error("POST_NOTIFICATIONS permission not granted and cannot open settings");
            }
            pendingAction = null;
            pendingArgs = null;
            pendingCallbackContext = null;
            waitingPermissionFromSettings = false;
        }
    }

    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        if (!waitingPermissionFromSettings || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return;
        }

        // Some devices trigger an immediate resume before user actually enters Settings.
        if (!pausedAfterOpeningSettings) {
            Log.d("CtyNotification", "onResume after settings ignored because app was not paused yet");
            return;
        }

        int now = cordova.getActivity().checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS);
        boolean enabled = NotificationManagerCompat.from(cordova.getActivity()).areNotificationsEnabled();
        Log.d("CtyNotification", "onResume after settings, POST_NOTIFICATIONS=" + (now == PackageManager.PERMISSION_GRANTED ? "GRANTED" : "DENIED") + ", notificationsEnabled=" + enabled);

        waitingPermissionFromSettings = false;
        pausedAfterOpeningSettings = false;
        if (permissionTimeoutRunnable != null) {
            mainHandler.removeCallbacks(permissionTimeoutRunnable);
            permissionTimeoutRunnable = null;
        }
        if (now == PackageManager.PERMISSION_GRANTED) {
            if (pendingAction != null && pendingArgs != null && pendingCallbackContext != null) {
                Log.d("CtyNotification", "Replaying pending action after manual permission grant: " + pendingAction);
                String action = pendingAction;
                JSONArray args = pendingArgs;
                CallbackContext callbackContext = pendingCallbackContext;
                pendingAction = null;
                pendingArgs = null;
                pendingCallbackContext = null;
                try {
                    execute(action, args, callbackContext);
                } catch (JSONException e) {
                    callbackContext.error("Failed to replay action after permission grant: " + e.getMessage());
                }
            }
        } else {
            if (pendingCallbackContext != null) {
                pendingCallbackContext.error("POST_NOTIFICATIONS permission denied in settings");
            }
            pendingAction = null;
            pendingArgs = null;
            pendingCallbackContext = null;
        }
    }

    @Override
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
        if (waitingPermissionFromSettings) {
            pausedAfterOpeningSettings = true;
            Log.d("CtyNotification", "onPause while waitingPermissionFromSettings=true");
        }
    }

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        super.onRequestPermissionResult(requestCode, permissions, grantResults);
        Log.d("CtyNotification", "onRequestPermissionResult: requestCode=" + requestCode + " permissions=" + (permissions != null ? permissions.length : 0) + " grantResults=" + (grantResults != null ? grantResults.length : 0));

        if (permissionTimeoutRunnable != null) {
            mainHandler.removeCallbacks(permissionTimeoutRunnable);
            permissionTimeoutRunnable = null;
        }
        
        if (requestCode == REQUEST_CODE_POST_NOTIFICATIONS) {  // Our POST_NOTIFICATIONS request
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d("CtyNotification", "POST_NOTIFICATIONS permission GRANTED");
                if (pendingAction != null && pendingArgs != null && pendingCallbackContext != null) {
                    Log.d("CtyNotification", "Replaying pending action after permission grant: " + pendingAction);
                    String action = pendingAction;
                    JSONArray args = pendingArgs;
                    CallbackContext callbackContext = pendingCallbackContext;
                    pendingAction = null;
                    pendingArgs = null;
                    pendingCallbackContext = null;
                    execute(action, args, callbackContext);
                }
            } else {
                boolean shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(
                        cordova.getActivity(),
                        Manifest.permission.POST_NOTIFICATIONS
                );
                Log.w("CtyNotification", "POST_NOTIFICATIONS permission DENIED by user, shouldShowRationale=" + shouldShowRationale);

                // If the system won't show dialog again (or ROM blocks it), guide user to Settings.
                if (!shouldShowRationale) {
                    Log.w("CtyNotification", "Permission dialog may be blocked or 'Don't ask again' selected, opening settings");
                    openNotificationSettingsForManualGrant();
                    return;
                }

                if (pendingCallbackContext != null) {
                    pendingCallbackContext.error("POST_NOTIFICATIONS permission denied");
                }
                pendingAction = null;
                pendingArgs = null;
                pendingCallbackContext = null;
            }
        }
    }
}
