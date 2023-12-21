package com.plugin.CtyNotification;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.widget.Toast;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public  class LoadImageTask implements Runnable{
    private Context context;
    private int notificationId;

    public  String title;
    public String subText;
    public String urlLargeIcon;
    public  String urlBigImage;

   public String message;
    public LoadImageTask(Context context, int notificationId,String title,String subText,String message,String urlLargeIcon,String urlBigImage) {
        this.context = context;
        this.notificationId = notificationId;
        this.title=title;
        this.subText=subText;
        this.message=message;
        this.urlLargeIcon=urlLargeIcon;
        this.urlBigImage=urlBigImage;
    }

    private Bitmap doInBackground(@NonNull String urls) {
        String imageUrl =urls;
        try {
            URL url = new URL(imageUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoInput(true);
            connection.connect();
            InputStream inputStream = connection.getInputStream();
            return BitmapFactory.decodeStream(inputStream);
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public void run() {
        //在后台执行任务
        Bitmap  Iconbitmap = null;
        Bitmap  Bigbitmap= null;
        if(urlLargeIcon!=null) {
            Iconbitmap=doInBackground(urlLargeIcon);
        }
        if(urlLargeIcon!=null) {
             Bigbitmap = doInBackground(urlBigImage);
        }

        // 更新主线程 UI
        Bitmap finalIconbitmap = Iconbitmap;
        Bitmap finalBigbitmap = Bigbitmap;
        ((Activity) context).runOnUiThread(new Runnable() {
            @Override
            public void run() {
                onPostExecute(finalIconbitmap, finalBigbitmap);
            }
        });

    }

    private void onPostExecute(Bitmap Iconbitmap,Bitmap Bigbitmap) {
        // 更新 UI
        //Toast.makeText(context, result, Toast.LENGTH_SHORT).show();
        CtyNotificationHelper.BigPictureNotice(context, notificationId,title,subText,message,Iconbitmap,Bigbitmap);
    }
}
