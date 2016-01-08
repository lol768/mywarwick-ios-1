(function(store) {
  var app = {
    unreadNotificationCount: 0,
    unreadActivityCount: 0,
    unreadNewsCount: 0,
    currentPath: '/',
    isUserLoggedIn: false,
    isUserIdentityLoaded: false,
    isAppCached: false
  };

  window.app = app;

  function getStreamSize(stream) {
    return stream.valueSeq().reduce(function (sum, part) {
      return sum + part.size;
    }, 0);
  }

  function setAppCached() {
    app.isAppCached = true;
    window.location = 'start://';
  }

  store.subscribe(function () {
    var getState = store.getState;

    app.unreadNotificationCount = getStreamSize(getState().get('notifications'));
    app.unreadActivityCount = getStreamSize(getState().get('activities'));
    app.unreadNewsCount = 0;
    app.currentPath = getState().get('path');
    app.isUserLoggedIn = getState().get('user').get('usercode') !== undefined;
    app.isUserIdentityLoaded = getState().get('user').get('loaded') === true;

    window.location = 'start://';
  });

  window.applicationCache.addEventListener('cached', setAppCached);
  window.applicationCache.addEventListener('noupdate', setAppCached);
  window.applicationCache.addEventListener('updateready', setAppCached);
  if (window.applicationCache.status === window.applicationCache.IDLE) {
    setAppCached();
  }
})(Store);
