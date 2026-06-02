const exec = require('cordova/exec');
const argscheck = require('cordova/argscheck');
const CTYNotification = require('./CtyNotificationConstants');
/**
 * @exports CTYNotification
 */
const CTYNotificationExport = {
}

let _apnsTokenCache = null;
let _apnsRequestInFlight = false;
let _apnsPendingCallbacks = [];

function _flushApnsSuccess(token) {
    const pending = _apnsPendingCallbacks.slice();
    _apnsPendingCallbacks = [];
    pending.forEach(({ successCallback, resolve }) => {
        if (typeof resolve === 'function') {
            try {
                resolve(token);
            } catch (_) {}
        }
        if (typeof successCallback === 'function') {
            try {
                console.log('[CTYNotification] invoking app successCallback');
                successCallback(token);
            } catch (e) {
                try {
                    console.error('[CTYNotification] app successCallback threw:', e);
                } catch (_) {}
            }
        }
    });
}

function _flushApnsError(err) {
    const pending = _apnsPendingCallbacks.slice();
    _apnsPendingCallbacks = [];
    pending.forEach(({ errorCallback, reject }) => {
        if (typeof reject === 'function') {
            try {
                reject(err);
            } catch (_) {}
        }
        if (typeof errorCallback === 'function') {
            try {
                console.log('[CTYNotification] invoking app errorCallback');
                errorCallback(err);
            } catch (e) {
                try {
                    console.error('[CTYNotification] app errorCallback threw:', e);
                } catch (_) {}
            }
        }
    });
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
        const notificationId = getValue(options.notificationId, Number((Date.now()+'').slice(4)));
    const title = getValue(options.title, '');
    const subtitle = getValue(options.subtitle, '');
    const message = getValue(options.message, '');
    const image = getValue(options.image, '');
    const thumbnail = getValue(options.thumbnail, '');
    const isLargeText = getValue(options.isLargeText, false);
    const isImportant = getValue(options.isImportant, false);
    const repeat = getValue(options.repeat, false);
    const total = getValue(options.total, 0);
    let delay = getValue(options.delay, '');
    let interval = getValue(options.interval, '');
        // Normalize delay: if numeric (seconds) convert to datetime string;
        // if non-empty string assume it's already a datetime string.
        const hasDelay = delay !== '' && delay !== null && delay !== undefined;
        if (hasDelay && !isNaN(Number(delay))) {
            const date = new Date(Date.now() + Number(delay) * 1000);
            delay = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
        }
    var notificationType = CTYNotification.NotificationType.COMMON;
    if(thumbnail||image){
        notificationType = CTYNotification.NotificationType.BIGIMAGE;
    }else if(isImportant){
        notificationType = CTYNotification.NotificationType.IMPORTANT;
    }else if(isLargeText){
        notificationType = CTYNotification.NotificationType.LARGETEXT;
    }
    // If interval is numeric and this is a repeating notification, keep it as seconds.
    // Only convert interval to a date string when it's a one-off (non-repeating) scheduled time.
    if (+interval && !repeat) {
        let date = new Date(+new Date() + interval*1000);
        interval = `${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
    }
    var timedType = notificationType;
        // If this is a repeating notification or a scheduled (delay) notification,
        // use the TIMED notification type so native code schedules it.
        if(repeat || (hasDelay && delay !== '')){
            notificationType = CTYNotification.NotificationType.TIMED;
        }
    // Debug log: help detect duplicate scheduling from JS side
    try {
        console.log('CTYNotification.exec:', {notificationId, title, delay, repeat, interval, total, notificationType, timedType});
    } catch (e) {}
    exec(successCallback, errorCallback, 'CtyNotification', notificationType, [notificationId, title, subtitle, message, thumbnail, image, delay, repeat, interval, timedType, total]);
}
CTYNotificationExport.cancelLocalNotification = function(successCallback, errorCallback, notificationId){
    exec(successCallback, errorCallback, 'CtyNotification', 'timedCancelNotice', [notificationId, '', '', '', '', '', '', true, '', '']);
}
CTYNotificationExport.getDeviceToken = function(successCallback, errorCallback){
    argscheck.checkArgs('FF', 'CTYNotificationExport.getDeviceToken', arguments);
    try {
        console.log('[CTYNotification] getDeviceToken invoked');
    } catch (e) {}

    let _resolve;
    let _reject;
    const promise = new Promise((resolve, reject) => {
        _resolve = resolve;
        _reject = reject;
    });

    if (_apnsTokenCache) {
        try {
            console.log('[CTYNotification] using cached APNs token');
        } catch (e) {}
        try {
            if (typeof window !== 'undefined') {
                window.__CTY_APNS_TOKEN__ = _apnsTokenCache;
            }
        } catch (_) {}
        if (typeof _resolve === 'function') {
            _resolve(_apnsTokenCache);
        }
        if (typeof successCallback === 'function') {
            try {
                successCallback(_apnsTokenCache);
            } catch (e) {
                try {
                    console.error('[CTYNotification] app successCallback threw:', e);
                } catch (_) {}
            }
        }
        return promise;
    }

    _apnsPendingCallbacks.push({ successCallback, errorCallback, resolve: _resolve, reject: _reject });

    if (_apnsRequestInFlight) {
        try {
            console.log('[CTYNotification] getDeviceToken already in-flight, callback queued');
        } catch (e) {}
        return promise;
    }

    _apnsRequestInFlight = true;

    const onSuccess = function (token) {
        _apnsRequestInFlight = false;
        _apnsTokenCache = token;
        try {
            console.log('[CTYNotification] APNs device token:', token);
        } catch (e) {}
        try {
            if (typeof window !== 'undefined') {
                window.__CTY_APNS_TOKEN__ = token;
                if (typeof window.dispatchEvent === 'function' && typeof CustomEvent === 'function') {
                    window.dispatchEvent(new CustomEvent('CTYNotificationDeviceToken', { detail: { token } }));
                }
            }
        } catch (_) {}
        _flushApnsSuccess(token);
    };

    const onError = function (err) {
        _apnsRequestInFlight = false;
        try {
            console.error('[CTYNotification] getDeviceToken failed:', err);
        } catch (e) {}
        _flushApnsError(err);
    };

    exec(onSuccess, onError, 'CtyNotification', 'getDeviceToken', []);
    return promise;
}

// getDeviceToken: request APNs device token and return it to JS
module.exports = CTYNotificationExport;