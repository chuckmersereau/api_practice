(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.integrationsService', integrationsService);

  integrationsService.$inject = ['api'];

  function integrationsService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.load = function () {
      api.call('get', 'preferences?integrations=true', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };
    svc.sync = function (service, success, error) {
      service = service.toLowerCase();
      if(service == 'mailchimp') {
        return api.call('get', 'mail_chimp_accounts/sync', { }, success, error);
      }
      if(service == 'prayer letters') {
        return api.call('get', 'prayer_letters_accounts/sync', { }, success, error);
      }
      if(service == 'pls') {
        return api.call('get', 'pls_accounts/sync', { }, success, error);
      }
    }
    svc.disconnect = function (service, success, error) {
      service = service.toLowerCase();
      if(service == 'mailchimp') {
        return api.call('delete', 'mail_chimp_accounts/' + svc.data.mail_chimp_account_id, { }, success, error);
      }
      if(service == 'prayer letters') {
        return api.call('delete', 'prayer_letters_accounts/' + svc.data.prayer_letters_account_id, { }, success, error);
      }
      if(service == 'pls') {
        return api.call('delete', 'pls_accounts/' + svc.data.pls_account_id, { }, success, error);
      }
    }
    svc.load();

    return svc;
  }
})();
