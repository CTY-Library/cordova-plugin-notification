package com.plugin.CtyNotification;

import android.app.AlarmManager;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.icu.text.SimpleDateFormat;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;


public class LocalNotificationScheduler {
    public static void scheduleLocalNotification(Context context,String title,String subText, String message,String urlLargeIcon,String urlBigImage,String strType,String strDate,boolean repeat) throws ParseException {
        // 获取AlarmManager系统服务
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);

        // 创建一个Intent，用于触发本地推送
        Intent notificationIntent = new Intent(context, NotificationReceiver.class);
        notificationIntent.putExtra("title",title);
        notificationIntent.putExtra("subText",subText);
        notificationIntent.putExtra("message",message);
        notificationIntent.putExtra("urlLargeIcon",urlLargeIcon);
        notificationIntent.putExtra("urlBigImage",urlBigImage);
        notificationIntent.putExtra("strType",strType);
        notificationIntent.putExtra("strDate",strDate);
        notificationIntent.putExtra("repeat",repeat);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);

        // 设置定时只执行一次
        SimpleDateFormat sdf = null;
        Date date=null;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA);
            date= sdf.parse(strDate);
        }
        if(repeat) {
            Calendar calendar = Calendar.getInstance();
            if(date!=null)
            {
                calendar.setTime(date);
                alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(),AlarmManager.INTERVAL_DAY,pendingIntent);
            }
        }
        else {
            alarmManager.set(AlarmManager.RTC_WAKEUP,date.getTime(),pendingIntent);
        }
    }
    public static class NotificationReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            String title=intent.getStringExtra("title");
            String subText=intent.getStringExtra("subText");
            String message=intent.getStringExtra("message");
            String urlLargeIcon=intent.getStringExtra("urlLargeIcon");
            String urlBigImage=intent.getStringExtra("urlBigImage");
            String strType=intent.getStringExtra("strType");
            boolean repeat=intent.getBooleanExtra("repeat",false);
            CtyNotificationHelper.CommonNotice(context, 5,title,subText, message);
        }
    }
}