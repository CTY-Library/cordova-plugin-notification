package com.plugin.CtyNotification;


import android.content.Context;
import android.net.ParseException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class CtyNoticePlugin extends  CordovaPlugin {
    private Context mActContext;
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
        String strType =args.getString(8); //通知时间

        mActContext = this.cordova.getActivity().getApplicationContext();

        //初始化
        if (action.equals("commonNotice")) {
            CtyNotificationHelper.CommonNotice(mActContext,notificationId,title,subText,message);
            callbackContext.success("success");
            true;
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
            Executor executor= Executors.newSingleThreadExecutor();
            executor.execute(new LoadImageTask(mActContext, notificationId,title,subText,message,urlLargeIco,urlBigImage));
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
        return  false;
    }
}
