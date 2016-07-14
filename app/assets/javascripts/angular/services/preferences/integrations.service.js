(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.integrationsService', integrationsService);

  integrationsService.$inject = ['$rootScope', 'api'];

  function integrationsService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;

    svc.load = function () {
      api.call('get', 'preferences/integrations', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.sync = function (service, success, error) {
      service = service.toLowerCase();
      if(service == 'prayer letters') {
        return api.call('get', 'preferences/integrations/prayer_letters_account/sync', { }, success, error);
      }
      if(service == 'pls') {
        return api.call('get', 'preferences/integrations/pls_account/sync', { }, success, error);
      }
    }

    svc.disconnect = function (service, success, error, id) {
      service = service.toLowerCase();
      if(service == 'google') {
        return api.call('delete', 'preferences/integrations/google_accounts/' + id, { }, success, error);
      }
      if(service == 'key') {
        return api.call('delete', 'preferences/integrations/key_accounts/' + id, { }, success, error);
      }
      if(service == 'prayer letters') {
        return api.call('delete', 'preferences/integrations/prayer_letters_account', { }, success, error);
      }
      if(service == 'pls') {
        return api.call('delete', 'preferences/integrations/pls_account', { }, success, error);
      }
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
