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

    native.setBackgroundToDisplay = function setBackgroundToDisplay(bgId, isHighContrast = false) {
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
 
    native.openMailApp = function openMailApp(externalApp) {
        if (externalApp === "mail") {
            global.location = "message://"
        } else if (externalApp === "outlook") {
            global.location = "ms-outlook://"
        }
    };

    var locationListeners = [];
    var locationErrorListeners = [];

    navigator.geolocation.getCurrentPosition = function getCurrentPosition(success, error, options) {
        locationListeners.push(success);
        locationErrorListeners.push(error);

        handler.postMessage({
            kind: 'geolocationGetCurrentPosition',
            options: options
        });
    };

    native.didUpdateLocation = function didUpdateLocation(position) {
        locationListeners.forEach(function (listener) {
            listener(position);
        });
        locationListeners = [];
    };

    native.locationDidFail = function locationDidFail(error) {
        locationErrorListeners.forEach(function (listener) {
            listener(error);
        });
        locationErrorListeners = [];
    };
 }(window, webkit.messageHandlers.MyWarwick));
