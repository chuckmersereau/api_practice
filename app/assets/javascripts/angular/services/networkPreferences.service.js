
(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('networkPreferencesService', networkPreferencesService);

  networkPreferencesService.$inject = ['api'];

  function networkPreferencesService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.load = function () {
      api.call('get', 'preferences?notifications=true', {}, function(data) {
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
      api.call('put', 'preferences/' + svc.data.current_account_list_id,
        { preference_set: svc.data },
        success,
        error);
    };

    svc.load();

    return svc;
  }
})();
