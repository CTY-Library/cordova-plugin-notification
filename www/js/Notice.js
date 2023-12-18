var exec = require('cordova/exec');

var CtyNoticePlugin = {
    //普通通知  
    commonNotice: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'commonNotice', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //大文本通知
    largeTextNotice: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'largeTextNotice', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //重要内容通知
    importantNotice: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'importantNotice', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //大图通知
    bigImageNotice: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'bigImageNotice', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //定时通知
    timedNotice: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'timedNotice', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    }
}

module.exports = CtyNoticePlugin