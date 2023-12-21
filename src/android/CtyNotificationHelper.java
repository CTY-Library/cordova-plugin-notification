package com.plugin.CtyNotification;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.os.SystemClock;
import android.util.Log;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import com.zhongzilian.chestnutapp.MainActivity;
import com.zhongzilian.chestnutapp.R;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class CtyNotificationHelper {

    //普通通知
    public static void CommonNotice(Context context, int NotificationId, String title,String subText, String message) {
        createNotificationChannel(context,NotificationId);

        // 创建一个新的PendingIntent
        PendingIntent pendingIntent = PendingIntent.getActivity(context, NotificationId, new Intent(context,MainActivity.class), 0);


        NotificationCompat.Builder builder = new NotificationCompat.Builder(context,Integer.toString(NotificationId))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setSubText(subText)
                .setContentText(message)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT);
        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(NotificationId, builder.build());
    }


    //重要通知
    public static void ImportantNotice(Context context, int NotificationId, String title,String subText,String message) {
        createNotificationChannel(context,NotificationId);

        // 创建一个新的PendingIntent
        PendingIntent pendingIntent = PendingIntent.getActivity(context, NotificationId, new Intent(context, MainActivity.class), 0);


        NotificationCompat.Builder builder = new NotificationCompat.Builder(context,Integer.toString(NotificationId))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setSubText(subText)
                .setContentText(message)
                .setAutoCancel(true)
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                .setNumber(999)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)//通知类别,"勿扰模式"时系统会决定要不要显示你的通知
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE); //屏幕可见性，锁屏时，显示icon和标题，内容隐藏


        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(NotificationId, builder.build());
    }

    //大文本通知
    public static void LargeTextNotice(Context context, int NotificationId, String title, String subText,String message) {
        createNotificationChannel(context,NotificationId);

        // 创建一个新的PendingIntent
        PendingIntent pendingIntent = PendingIntent.getActivity(context, NotificationId, new Intent(context, MainActivity.class), 0);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context,Integer.toString(NotificationId))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setSubText(subText)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(message))
                .setAutoCancel(true)
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                .setNumber(999)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)//通知类别,"勿扰模式"时系统会决定要不要显示你的通知
                .setContentIntent(pendingIntent)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE);//屏幕可见性，锁屏时，显示icon和标题，内容隐藏

        Log.d(title, "showNotification: showNotification");

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(NotificationId, builder.build());
    }

    //大图片通知
    public static void BigPictureNotice(Context context, int NotificationId, String title, String subText,String message, Bitmap Iconbitmap,Bitmap Bigbitmap) {
        createNotificationChannel(context,NotificationId);

        Resources resources=context.getResources();
        Bitmap bigPicTwo=BitmapFactory.decodeResource(resources,R.mipmap.ic_launcher);
        // 创建一个新的PendingIntent
        PendingIntent pendingIntent = PendingIntent.getActivity(context, NotificationId, new Intent(context, MainActivity.class), 0);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context,Integer.toString(NotificationId))
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setSubText(subText)
                .setContentText(message)
                .setStyle(new NotificationCompat.BigPictureStyle().bigPicture(Bigbitmap))
                .setLargeIcon(Iconbitmap)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setContentIntent(pendingIntent);


        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(context);
        notificationManager.notify(NotificationId, builder.build());
    }

    public   static void createNotificationChannel(Context context,int NotificationId) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(Integer.toString(NotificationId), "CHANNEL_NAME", NotificationManager.IMPORTANCE_DEFAULT);
            NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    public static Bitmap getBitmapFromURL(String urlString) {
        try {
            URL url = new URL(urlString);
            InputStream inputStream = url.openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
            inputStream.close();
            return bitmap;
        }
        catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }
}
