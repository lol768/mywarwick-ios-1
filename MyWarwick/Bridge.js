(function iosBridge(global, handler) {
    var native = {};
    global.MyWarwickNative = native;

    native.ready = function ready() {
        handler.postMessage({
            kind: 'ready',
        });
    };

    native.setUser = function setUser(user) {
        handler.postMessage({
            kind: 'setUser',
            user: user,
        });
    };

    native.setWebSignOnUrls = function setWebSignOnUrls(signInUrl, signOutUrl) {
        handler.postMessage({
            kind: 'setWebSignOnUrls',
            signInUrl: signInUrl,
            signOutUrl: signOutUrl,
        });
    };

    native.setUnreadNotificationCount = function setUnreadNotificationCount(count) {
        handler.postMessage({
            kind: 'setUnreadNotificationCount',
            count: count,
        });
    };

    native.setPath = function setPath(path) {
        handler.postMessage({
            kind: 'setPath',
            path: path,
        });
    };

    native.setAppCached = function setAppCached(cached) {
        handler.postMessage({
            kind: 'setAppCached',
            cached: cached,
        });
    };

    native.setBackgroundToDisplay = function setBackgroundToDisplay(bgId, isHighContrast) {
        if (isHighContrast === undefined) {
            isHighContrast = false
        }
 
        handler.postMessage({
            kind: 'setBackgroundToDisplay',
            bgId: bgId,
            isHighContrast: isHighContrast
        })
    };

    native.loadDeviceDetails = function loadDeviceDetails() {
        handler.postMessage({
            kind: 'loadDeviceDetails',
        });
    };

    native.getAppVersion = function getAppVersion() {
        return "{{APP_VERSION}}";
    };

    native.getAppBuild = function getAppBuild() {
        return "{{APP_BUILD}}";
    };

    native.launchTour = function launchTour() {
        handler.postMessage({
            kind: 'launchTour',
        });
    };

    native.setTimetableToken = function setTimetableToken(token) {
        handler.postMessage({
            kind: 'setTimetableToken',
            token: token,
        });
    };

    native.setTimetableNotificationsEnabled = function setTimetableNotificationsEnabled(enabled) {
        handler.postMessage({
            kind: 'setTimetableNotificationsEnabled',
            enabled: enabled,
        });
    };

    native.setTimetableNotificationTiming = function setTimetableNotificationTiming(timing) {
        handler.postMessage({
            kind: 'setTimetableNotificationTiming',
            timing: timing,
        });
    };
 
    native.setTimetableNotificationsSoundEnabled = function setTimetableNotificationsSoundEnabled(enabled) {
        handler.postMessage({
            kind: 'setTimetableNotificationsSoundEnabled',
            enabled: enabled,
        });
    };

    native.openMailApp = function openMailApp(externalApp) {
        if (externalApp === "mail") {
            global.location = "message://"
        } else if (externalApp === "outlook") {
            global.location = "ms-outlook://"
        }
    };

    var locationListeners = [];
    var locationErrorListeners = [];

    var watchLocationListeners = {};
    var nextWatchId = 1;
    var watchCount = 0;

    navigator.geolocation.getCurrentPosition = function getCurrentPosition(success, error, options) {
        locationListeners.push(success);
        locationErrorListeners.push(error);

        handler.postMessage({
            kind: 'geolocationGetCurrentPosition',
            options: options,
        });
    };

    navigator.geolocation.watchPosition = function watchPosition(success, error, options) {
        watchCount++;
        var watchId = nextWatchId++;

        watchLocationListeners[watchId] = {
            success: success,
            error: error,
        };

        if (watchCount === 1) {
            handler.postMessage({
                kind: 'geolocationWatchPosition',
                options: options,
            });
        }

        return watchId;
    };

    navigator.geolocation.clearWatch = function clearWatch(watchId) {
        delete watchLocationListeners[watchId];

        watchCount--;

        if (watchCount === 0) {
            handler.postMessage({
                kind: 'geolocationClearWatch',
            });
        }
    };

    native.didUpdateLocation = function didUpdateLocation(position) {
        locationListeners.forEach(function (listener) {
            listener(position);
        });
        locationListeners = [];

        for (var watchId in watchLocationListeners) {
            watchLocationListeners[watchId].success(position);
        }

        var frames = document.getElementsByTagName('iframe');
        for (var i = 0; i < frames.length; i++) {
            frames[i].contentWindow.postMessage({
                type: 'location',
                position: position,
            }, '*');
        }
    };

    native.locationDidFail = function locationDidFail(error) {
        locationErrorListeners.forEach(function (listener) {
            listener(error);
        });
        locationErrorListeners = [];
    };

    global.addEventListener('message', function receiveMessage(event) {
        if (event.data.type === 'location') {
            native.didUpdateLocation(event.data.position);
        }
    });
}(window, webkit.messageHandlers.MyWarwick));
