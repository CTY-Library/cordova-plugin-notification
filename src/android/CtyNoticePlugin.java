package com.plugin.CtyNotification;


import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.ParseException;
import android.os.Build;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;


public class CtyNoticePlugin extends  CordovaPlugin {
    private Context mActContext;
    private static final String PERMISSION = Manifest.permission.ACCESS_NOTIFICATION_POLICY;

    @Override
     public void initialize(CordovaInterface cordova, CordovaWebView webView){
        super.initialize(cordova,webView);
        mActContext = this.cordova.getActivity().getApplicationContext();
     }    

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        int notificationId =Integer.parseInt(args.getString(0)); //通知的Id
        int permissionStatus = 0;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            permissionStatus = cordova.getActivity().checkSelfPermission(Manifest.permission.ACCESS_NOTIFICATION_POLICY);
        }
        if (permissionStatus != PackageManager.PERMISSION_GRANTED) {
                // 已经具有通知权限
            // 申请通知权限
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestPermissions(callbackContext);
            }
            //callbackContext.error("没有发送通知的权限，正在申请权限");
            //return  true;
        }
        String title =args.getString(1); //标题
        String subText =args.getString(2); //子标题
        String message =args.getString(3); //通知的内容
        String urlLargeIco =args.getString(4); //大图标
        String urlBigImage =args.getString(5); //大图
        String strDate =args.getString(6); //通知时间
        boolean strRepeat =Boolean.parseBoolean(args.getString(7)); //是否重复推送
        String strType =args.getString(8); //通知时间

        //初始化
        if (action.equals("commonNotice")) {
            CtyNotificationHelper.CommonNotice(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return true;
        }
        else if (action.equals("largeTextNotice")) {
            CtyNotificationHelper.LargeTextNotice(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return  true;
        }
       else  if (action.equals("importantNotice")) {
            CtyNotificationHelper.ImportantNotice(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            return  true;
        }
       else if (action.equals("bigImageNotice")) {
            cordova.getThreadPool().execute(new LoadImageTask(mActContext, notificationId,title,subText,message,urlLargeIco,urlBigImage));
            callbackContext.success("success");
            return  true;
       }
       else if (action.equals("timedNotice")) {
            try {
                LocalNotificationScheduler.scheduleLocalNotification(mActContext,notificationId,title,subText,message,urlLargeIco,urlBigImage,strType, strDate,strRepeat);
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
        else if (action.equals("timedCancelNotice")) {
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            int permission = PackageManager.PERMISSION_DENIED;
            String[] permissions = new String[]{
                    Manifest.permission.POST_NOTIFICATIONS,
                    Manifest.permission.ACCESS_NOTIFICATION_POLICY
            };
            cordova.requestPermissions(this, permission, permissions);
        } else {
            callbackContext.success();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == PackageManager.PERMISSION_DENIED) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {

            } else {
            }
        }
    }
}
