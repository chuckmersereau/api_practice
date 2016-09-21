(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.accounts.usersService', usersService);

  usersService.$inject = ['$rootScope', 'api'];

  function usersService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;

    svc.load = function () {
      svc.loading = true;
      api.call('get', 'preferences/accounts/users', { }, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.destroy = function (id, success, error) {
      return api.call('delete', 'preferences/accounts/users/' + id, { }, success, error);
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
