var exec = require('cordova/exec');

var CtyLocationNotification = {
    //普通通知  
    commonNotification: function(
        success,
        error,
        notificationId,
        title,
        subText,
        message,
        urlLargeIco,
        urlBigImage,
        strDate,
        strRepeat,
        strInterval,
        strType,
    ) {
        exec(success, error, 'CtyNotification', 'commonNotification', [notificationId,title, subText, message, urlLargeIco,urlBigImage,strDate,strRepeat,strInterval,strType]);
    }
}

module.exports = CtyLocationNotification