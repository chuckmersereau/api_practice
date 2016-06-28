
(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.notificationsService', notificationsService);

  notificationsService.$inject = ['$rootScope', 'api'];

  function notificationsService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    
    svc.load = function () {
      api.call('get', 'preferences/notifications', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.toggleNotification = function (field_name, notification_type) {
      var index = svc.data[field_name].actions.indexOf(notification_type);
      if (index === -1) {
        svc.data[field_name].actions.push(notification_type);
      } else {
        svc.data[field_name].actions.splice(index, 1);
      }
    };

    svc.save = function(success, error) {
      api.call('put', 'preferences',
        { preference_set: svc.data },
        success,
        error);
    };

    svc.account_list_id_watcher = $rootScope.$watch(function() {
      return api.account_list_id;
    }, function watchCallback() {
      svc.load();
    });

    svc.load();
    return svc;
  }
})();
