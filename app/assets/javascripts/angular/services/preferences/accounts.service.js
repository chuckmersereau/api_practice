(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.accountsService', accountsService);

  accountsService.$inject = ['$rootScope', 'api'];

  function accountsService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.account_list_id = null;

    svc.load = function () {
      api.call('get', 'preferences/accounts', { list: true }, function(data) {
        svc.data = data.preferences;
        svc.account_list_id = data.preferences.account_list_id;
        svc.loading = false;
      });
    };

    svc.account_list_id_watcher = $rootScope.$watch(function() {
      return svc.account_list_id;
    }, function watchCallback(account_list_id) {
      api.account_list_id = account_list_id;
    });

    svc.load();
    return svc;
  }
})();
