package cty.cordova.plugin.CtyNotification;

import android.Manifest;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.icu.text.SimpleDateFormat;
import android.net.Uri;
import android.provider.Settings;
import android.os.Build;
import android.util.Log;

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
        Log.d("CtyNotification", "scheduleLocalNotification called requestCode=" + requestCode + " title=" + title + " strDate=" + strDate + " interval=" + interval + " repeat=" + repeat);
        // 获取AlarmManager系统服务
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);

        // 创建一个Intent，用于触发本地推送
        Intent notificationIntent = new Intent(context, NotificationReceiver.class);
        // include notificationId for receiver
        notificationIntent.putExtra("notificationId", requestCode);
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
            Log.d("CtyNotification", "scheduleLocalNotification: repeat branch, interval=" + interval);
            Calendar calendar = Calendar.getInstance();
            if(date!=null)
            {
                calendar.setTime(date);
                if(interval.indexOf("-")>0)
                {
                    // interval expressed as complex components (month-day-hour-minute-second)
                    // schedule a single exact alarm and let the receiver reschedule the next occurrence
                    long triggerAt = calendar.getTimeInMillis();
                    // If app cannot schedule exact alarms (Android 12+), request user to grant and fallback to inexact set
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                        Log.w("CtyNotification", "Cannot schedule exact alarms; requesting user grant and falling back to inexact alarm");
                        try {
                            Intent intent = new Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
                            intent.setData(Uri.fromParts("package", context.getPackageName(), null));
                            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            context.startActivity(intent);
                        } catch (Exception e) {
                            Log.e("CtyNotification", "Failed to start exact alarm settings activity", e);
                        }
                        // fallback to inexact alarm to avoid exception
                        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent);
                    } else {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent);
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent);
                        } else {
                            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent);
                        }
                    }
                }
                else
                {
                    long intervalMillis = Integer.parseInt(interval) * 1000L;
                    long triggerAt = calendar.getTimeInMillis();
                    long now = System.currentTimeMillis();
                    if (triggerAt <= now) {
                        long missed = now - triggerAt;
                        long steps = missed / intervalMillis + 1;
                        triggerAt += steps * intervalMillis;
                        Log.d("CtyNotification", "scheduleLocalNotification: adjusted triggerAt to next future occurrence=" + triggerAt);
                    }
                    Log.d("CtyNotification", "scheduleLocalNotification: numeric intervalMillis=" + intervalMillis + " nextTrigger=" + triggerAt);
                    alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, triggerAt, intervalMillis, pendingIntent);
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
            Log.d("CtyNotification", "NotificationReceiver onReceive: id=" + notificationId + " extras=" + intent.getExtras());
            
            // Check POST_NOTIFICATIONS permission
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    Log.w("CtyNotification", "NotificationReceiver: POST_NOTIFICATIONS permission not granted, aborting notification display");
                    return;
                }
            }
            Log.d("CtyNotification", "NotificationReceiver: permission check passed");
            
            String title=intent.getStringExtra("title");
            String subText=intent.getStringExtra("subText");
            String message=intent.getStringExtra("message");
            String urlLargeIcon=intent.getStringExtra("urlLargeIcon");
            String urlBigImage=intent.getStringExtra("urlBigImage");
            String strType=intent.getStringExtra("strType");
            if (strType == null || strType.isEmpty()) {
                Log.d("CtyNotification", "NotificationReceiver: missing strType, aborting processing. extras=" + intent.getExtras());
                return;
            }
            String interval=intent.getStringExtra("interval");
            String strDate=intent.getStringExtra("strDate");
            boolean strRepeat = intent.getBooleanExtra("repeat", false); //是否重复推送
            switch (strType)
            {
                // Match the NotificationType strings emitted by the JS layer (e.g. 'commonNotification')
                case "commonNotification":
                    CtyNotificationHelper.CommonNotification(context, notificationId,title,subText, message);
                    break;
                case "largeTextNotification":
                    CtyNotificationHelper.LargeTextNotification(context, notificationId,title,subText, message);
                    break;
                case "importantNotification":
                    CtyNotificationHelper.ImportantNotification(context, notificationId,title,subText, message);
                    break;
                case "bigImageNotification":
                    execute(new LoadImageTask(context, notificationId,title,subText,message,urlLargeIcon,urlBigImage));
                    break;
                default:
                    break;
            }
            if(interval.indexOf("-")>0)
            {
                Log.d("CtyNotification", "NotificationReceiver: complex interval, will compute next date and reschedule. interval=" + interval + " strDate=" + strDate);
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
        // Submit to a shared single-thread executor to avoid creating many short-lived pools
        THREAD_POOL.submit(runnable);
    }

    // Reuse a single-thread executor for all scheduled work to avoid resource leaks
    private static final ThreadPoolExecutor THREAD_POOL = new ThreadPoolExecutor(
            1,
            1,
            0L,
            TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>()
    );
}