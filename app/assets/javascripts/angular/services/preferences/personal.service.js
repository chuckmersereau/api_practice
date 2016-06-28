(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.personalService', personalService);

  personalService.$inject = ['$rootScope', 'api'];

  function personalService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;

    svc.load = function () {
      api.call('get', 'preferences/personal', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.save = function(success, error) {
      api.call('put', 'preferences',
        { preference_set: this.data },
        success,
        error);
    }

    svc.account_list_id_watcher = $rootScope.$watch(function() {
      return api.account_list_id;
    }, function watchCallback() {
      svc.load();
    });

    svc.load();
    return svc;
  }
})();
