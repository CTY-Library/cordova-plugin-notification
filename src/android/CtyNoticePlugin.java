package com.plugin.CtyNotification;


import android.content.Context;
import android.net.ParseException;
import android.os.Build;

import androidx.annotation.RequiresApi;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

public class CtyNoticePlugin extends  CordovaPlugin {
    private Context mActContext;

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        mActContext = this.cordova.getActivity().getApplicationContext();
    }


    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        int notificationId =Integer.parseInt(args.getString(0)); //通知的Id
        String title =args.getString(1); //标题
        String subText =args.getString(2); //子标题
        String message =args.getString(3); //通知的内容
        String urlLargeIco =args.getString(4); //大图标
        String urlBigImage =args.getString(5); //大图
        String strDate =args.getString(6); //通知时间
        boolean strRepeat =Boolean.parseBoolean(args.getString(7)); //是否重复推送
        //初始化
        if (action.equals("commonNotice")) {
            CtyNotificationHelper.CommonNotice(mActContext,notificationId,title,subText,message);
            return  true;
        }
        if (action.equals("largeTextNotice")) {
            CtyNotificationHelper.LargeTextNotice(mActContext,notificationId,title,subText,message);
            return  true;
        }
        if (action.equals("importantNotice")) {
           CtyNotificationHelper.ImportantNotice(mActContext,notificationId,title,subText,message);
            return  true;
        }
        if (action.equals("bigImageNotice")) {
            LoadImageTask loadImageTask = new LoadImageTask(mActContext, notificationId,title,subText,message);
            loadImageTask.execute(urlBigImage);
            return  true;
        }
        if (action.equals("timedNotice")) {
            try {
                LocalNotificationScheduler.scheduleLocalNotification(mActContext,title,subText,message,urlLargeIco,urlBigImage,"", strDate,strRepeat);
                return  true;
            } catch (ParseException e) {
                throw new RuntimeException(e);
            } catch (java.text.ParseException e) {
                throw new RuntimeException(e);
            }
        }
        return  false;
    }
}