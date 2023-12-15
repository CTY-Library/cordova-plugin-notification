package com.plugin.CtyNotification;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public  class LoadImageTask extends AsyncTask<String, Void, Bitmap> {
    private Context context;
    private int notificationId;

    public  String title;
    public String subText;

   public String message;

    public LoadImageTask(Context context, int notificationId,String title,String subText,String message) {
        this.context = context;
        this.notificationId = notificationId;
        this.title=title;
        this.subText=subText;
        this.message=message;
    }

    @Override
    protected Bitmap doInBackground(String... urls) {
        String imageUrl = urls[0];
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
    protected void onPostExecute(Bitmap bitmap) {
        if (bitmap != null) {
           CtyNotificationHelper.BigPictureNotice(context, notificationId,title,subText,message,bitmap);
        }
    }
}
