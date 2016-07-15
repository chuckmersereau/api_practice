(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.accounts.mergesService', mergesService);

  mergesService.$inject = ['$rootScope', 'api', 'preferences.accountsService'];

  function mergesService($rootScope, api, accountsService) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.selected_account_id = null;

    svc.load = function () {
      svc.loading = true;
      api.call('get', 'preferences/accounts/merges', { }, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.create = function (success, error) {
      return api.call('post', 'preferences/accounts/merges', { merge: { id: svc.selected_account_id } }, function() {
        accountsService.load();
        success();
      }, error);
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
