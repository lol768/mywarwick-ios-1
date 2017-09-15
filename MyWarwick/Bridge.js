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

    native.setBackgroundToDisplay = function setBackgroundToDisplay(bgId) {
        handler.postMessage({
            kind: 'setBackgroundToDisplay',
            bgId: bgId
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
    }
 }(window, webkit.messageHandlers.MyWarwick));
