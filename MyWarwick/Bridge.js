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
    }
}(window, webkit.messageHandlers.MyWarwick));
