const exec = require('cordova/exec');
const argscheck = require('cordova/argscheck');
const CTYNotification = require('./CtyNotificationConstants');
/**
 * @exports CTYNotification
 */
const CTYNotificationExport = {
}
// Tack on the CTYNotification Constants to the base CTYNotification plugin.
for (const key in CTYNotification) {
    CTYNotificationExport[key] = CTYNotification[key];
}
/**
 * Callback function that provides an error message.
 * @callback module:CTYNotification.onError
 * @param {string} message - The message is provided by the device's native code.
 */

/**
 * Callback function that provides the Mark of success.
 * @callback module:CTYNotification.onSuccess
 * @param {boolean} isSendSuccessful - True if the notification was sent successfully, false otherwise.
 *
 */

/**
 * Optional parameters to customize the notification settings.
 * * [Quirks](#NotificationOptions-quirks)
 * @typedef module:CTYNotification.NotificationOptions
 * @type {Object}
 * @property {number} [notificationId=Number((Date.now()+'').slice(4))] - The id of the notification.
 * @property {string} [title] - The title of the notification.
 * @property {string} [subtitle] - The subtitle of the notification.
 * @property {string} [message] - The message of the notification.
 * @property {string} [image] - The image of the notification.
 * @property {string} [thumbnail] -Android-only The thumbnail of the notification.
 * @property {Boolean} [isLargeText=false] - Whether the message content of the notification is too large is collapsed
 * @property {Boolean} [isImportant=false] - Is not important message notification
 * @property {Boolean} [repeat=false] - Whether to repeat message notification
 * @property {module:Notification.DelayType, string, number} [delay=0] - Message notification delay time
 * @property {module:Notification.IntervalType, string, number} [interval=0] - The time to repeat the message notification. Only works when `repeat` is `true`
 * @property {module:Notification.NotificationType, string} [timedType=COMMON] - The time to repeat the message notification. Only works when `repeat` is `true`
 */

/**
 * @description Support local message notification, including timing, delay and repeated message notification functions
 * 
 * __Supported Platforms__
 *
 * - Android
 * - Browser
 *
 * @example
 * CTYNotification.sendLocalNotification(onSuccess, onError, NotificationOptions);
 * @param {module:CTYNotification.onSuccess} successCallback
 * @param {module:CTYNotification.onError} errorCallback
 * @param {module:CTYNotification.NotificationOptions} options NotificationOptions
 */
CTYNotificationExport.sendLocalNotification = function(successCallback, errorCallback, options){
    argscheck.checkArgs('fFO', 'CTYNotificationExport.sendLocalNotification', arguments);
    options = options || {};
    const getValue = argscheck.getValue;
    const notificationId = getValue(options.quality, Number((Date.now()+'').slice(4)));
    const title = getValue(options.title, '');
    const subtitle = getValue(options.subtitle, '');
    const message = getValue(options.message, '');
    const image = getValue(options.image, '');
    const thumbnail = getValue(options.thumbnail, '');
    const isLargeText = getValue(options.isLargeText, false);
    const isImportant = getValue(options.isImportant, false);
    const repeat = getValue(options.repeat, false);
    let delay = getValue(options.delay, '');
    let interval = getValue(options.interval, '');
    var notificationType = CTYNotification.NotificationType.COMMON;
    if(thumbnail||image){
        notificationType = CTYNotification.NotificationType.BIGIMAGE;
    }else if(isImportant){
        notificationType = CTYNotification.NotificationType.IMPORTANT;
    }else if(isLargeText){
        notificationType = CTYNotification.NotificationType.LARGETEXT;
    }
    if(+delay){
        let date = new Date(+new Date() + delay*1000);
        delay = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
    }
    if(+interval){
        let date = new Date(+new Date() + interval*1000);
        interval = `${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
    }
    var timedType = notificationType;
    if(repeat){
        notificationType = CTYNotification.NotificationType.TIMED;
    }
    exec(successCallback, errorCallback, 'CtyNotification', notificationType, [notificationId, title, subtitle, message, thumbnail, image, delay, repeat, interval, timedType]);
}
CTYNotificationExport.cancelLocalNotification = function(successCallback, errorCallback, notificationId){
    exec(successCallback, errorCallback, 'CtyNotification', 'timedCancelNotice', [notificationId, '', '', '', '', '', '', true, '', '']);
}
CTYNotificationExport.getDeviceToken = function(successCallback, errorCallback,){
    exec(successCallback, errorCallback, 'CtyNotification', 'getDeviceToken']);
}
module.exports = CTYNotificationExport;