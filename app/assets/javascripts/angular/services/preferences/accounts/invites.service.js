(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.accounts.invitesService', invitesService);

  invitesService.$inject = ['$rootScope', 'api'];

  function invitesService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;

    svc.load = function () {
      svc.loading = true;
      api.call('get', 'preferences/accounts/invites', { }, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.destroy = function (id, success, error) {
      return api.call('delete', 'preferences/accounts/invites/' + id, { }, success, error);
    };

    svc.create = function (email, success, error) {
      return api.call('post', 'preferences/accounts/invites', { invite: { email: email } }, success, error);
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
