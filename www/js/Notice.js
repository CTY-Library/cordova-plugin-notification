var exec = require('cordova/exec');

var CtyNoticePlugin = {
    //普通通知  
    commonNotice: function(
        success,
        error,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'commonNotice', [title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //大文本通知
    largeTextNotice: function(
        success,
        error,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'largeTextNotice', [title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //重要内容通知
    importantNotice: function(
        success,
        error,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'importantNotice', [title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //大图通知
    bigImageNotice: function(
        success,
        error,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'bigImageNotice', [title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    },
    //定时通知
    timedNotice: function(
        success,
        error,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat
    ) {
        exec(success, error, 'CtyNoticePlugin', 'timedNotice', [title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat]);
    }
}

module.exports = CtyNoticePlugin