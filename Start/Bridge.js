(function(store) {
  function getStreamSize(stream) {
    return stream.valueSeq().reduce(function (sum, part) {
      return sum + part.size;
    }, 0);
  }

  function setAppCached() {
    app.isAppCached = true;
  }

  store.subscribe(function () {
    var getState = store.getState;

    app.unreadNotificationCount = getStreamSize(getState().get('notifications'));
    app.unreadActivityCount = getStreamSize(getState().get('activities'));
    app.unreadNewsCount = 0;
    app.currentPath = getState().get('path');
    app.isUserLoggedIn = getState().get('user').get('usercode') !== undefined;
    app.isUserIdentityLoaded = getState().get('user').get('loaded') === true;
  });

  window.applicationCache.addEventListener('cached', setAppCached);
  if (window.applicationCache.status === window.applicationCache.IDLE) {
    setAppCached();
  }
})(Store);
