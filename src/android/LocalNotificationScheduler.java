package cty.cordova.plugin.CtyNotification;

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
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;


public class LocalNotificationScheduler {
    //定时通知
    public static void scheduleLocalNotification(Context context,int requestCode,String title,String subText, String message,String urlLargeIcon,String urlBigImage,String strType,String strDate,boolean repeat) throws ParseException {
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
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, requestCode, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT| PendingIntent.FLAG_IMMUTABLE);

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

    //取消定时通知
    public static void scheduleCancelLocalNotification(Context context,int requestCode) throws ParseException {
        // 获取AlarmManager系统服务
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);

        // 创建一个Intent，用于触发本地推送
        Intent notificationIntent = new Intent(context, NotificationReceiver.class);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, requestCode, notificationIntent, PendingIntent.FLAG_NO_CREATE | PendingIntent.FLAG_IMMUTABLE);

        if(pendingIntent!=null&&alarmManager!=null)
        {
            //取消定时通知
            alarmManager.cancel(pendingIntent);
        }
    }

    public static class NotificationReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            int notificationId =intent.getIntExtra("notificationId",0);
            String title=intent.getStringExtra("title");
            String subText=intent.getStringExtra("subText");
            String message=intent.getStringExtra("message");
            String urlLargeIcon=intent.getStringExtra("urlLargeIcon");
            String urlBigImage=intent.getStringExtra("urlBigImage");
            String strType=intent.getStringExtra("strType");
            switch (strType)
            {
                case "commonNotice":
                    CtyNotificationHelper.CommonNotification(context, notificationId,title,subText, message);
                    break;
                case "largeTextNotice":
                    CtyNotificationHelper.LargeTextNotification(context, notificationId,title,subText, message);
                    break;
                case "importantNotice":
                    CtyNotificationHelper.ImportantNotification(context, notificationId,title,subText, message);
                    break;
                case "bigImageNotice":
                    execute(new LoadImageTask(context, notificationId,title,subText,message,urlLargeIcon,urlBigImage));
                    break;
                default:
                    break;
            }
        }
    }
    public static void execute(Runnable runnable) {
        // 创建一个线程池
        ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(1, 1, 0L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<>());
        // 提交任务到线程池
        threadPoolExecutor.submit(runnable);
    }
}