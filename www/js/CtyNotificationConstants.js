/**
 * @module Notification
 */
module.exports = {
    /**
     * @description
     * Presets a common delay
     * @enum {number}
     */
    DelayType: {
        MINUTES:60000,
        HOURS:3600000,
        DAYS:86400000,
        WEEKS:604800000,
        MONTHS:2592000000,
        YEARS:31536000000
    },
    /**
     * @description
     * Preset a common timing
     * @enum {number|string}
     */
    IntervalType: {
        MINUTES:60000,
        HOURS:3600000,
        DAYS:86400000,
        WEEKS:604800000,
        MONTHS:2592000000,
        YEARS:31536000000,
        FIRSTDAY:'01-01 00:00:00',
        LASTDAY:'12-31 23:59:59'
    },
    /**
     * @description
     * Preset a common timing
     * @enum {number|string}
     */
    NotificationType: {
        COMMON:'commonNotification',
        LARGETEXT:'largeTextNotification',
        IMPORTANT:'importantNotification',
        BIGIMAGE:'bigImageNotification',
        TIMED:'timedNotication'
    }
}