package cty.cordova.plugin.CtyNotification;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.icu.text.SimpleDateFormat;
import android.os.Build;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;


public class LocalNotificationScheduler {
    //定时通知
    public static void scheduleLocalNotification(Context context,int requestCode,String title,String subText, String message,String urlLargeIcon,String urlBigImage,String strType,String strDate,String interval,boolean repeat) throws ParseException {
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
        notificationIntent.putExtra("interval",interval);
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
                if(interval.indexOf("-")>0)
                {
                    alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(),0,pendingIntent);
                }
                else
                {
                    alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), Integer.parseInt(interval)*1000,pendingIntent);
                }
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
            String interval=intent.getStringExtra("interval");
            String strDate=intent.getStringExtra("strDate");
            String repeat=intent.getStringExtra("repeat");
            boolean strRepeat =Boolean.parseBoolean(repeat); //是否重复推送
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
            if(interval.indexOf("-")>0)
            {
                SimpleDateFormat sdf = null;
                Date date=null;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA);
                    try {
                        date= sdf.parse(strDate);
                    } catch (ParseException e) {
                        throw new RuntimeException(e);
                    }
                }
                // 将字符串分割成月、日、时、分、秒
                String[] parts = interval.split("[- :]");
                // 获取月
                int month = Integer.parseInt(parts[0]);
                // 获取日
                int day = Integer.parseInt(parts[1]);
                // 获取时
                int hour = Integer.parseInt(parts[2]);
                // 获取分
                int minute = Integer.parseInt(parts[3]);
                // 获取秒
                int second = Integer.parseInt(parts[4]);
                Calendar calendar = Calendar.getInstance();
                calendar.setTime(date);
                calendar.add(Calendar.MONTH,month);
                calendar.add(Calendar.DAY_OF_MONTH,day);
                calendar.add(Calendar.HOUR_OF_DAY,hour);
                calendar.add(Calendar.MINUTE,minute);
                calendar.add(Calendar.SECOND,second);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    strDate=sdf.format(calendar.getTime());
                }

                try {
                    LocalNotificationScheduler.scheduleLocalNotification(context,notificationId,title,subText,message,urlLargeIcon,urlBigImage,strType,strDate,interval,strRepeat);
                } catch (ParseException e) {
                    throw new RuntimeException(e);
                }
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