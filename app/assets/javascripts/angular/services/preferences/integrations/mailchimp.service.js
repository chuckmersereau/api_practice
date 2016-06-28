(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.integrations.mailchimpService', mailchimpService);

  mailchimpService.$inject = ['api'];

  function mailchimpService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.state = 'disabled';
    svc.load = function () {
      api.call('get', 'preferences/integrations/mail_chimp_account', {}, function(data) {
        svc.data = data.mail_chimp;
        svc.updateState();
        svc.loading = false;
      });
    };

    svc.save = function(success, error) {
      api.call('put', 'preferences/integrations/mail_chimp_account', { mail_chimp: this.data },
        function (data) {
          svc.data = data.mail_chimp;
          svc.updateState();
          success(data);
        },
        error);
    };


    svc.sync = function (success, error) {
      api.call('get', 'preferences/integrations/mail_chimp_account/sync', { }, success, error);
    };

    svc.disconnect = function (success, error) {
      api.call('delete', 'preferences/integrations/mail_chimp_account', { }, success, error);
    };

    svc.updateState = function () {
      if (svc.data.active) {
        if (svc.data.valid) {
          svc.state = 'enabled';
        } else {
          svc.state = 'error';
        }
      } else {
        svc.state = 'disabled';
      }
    };

    svc.load();

    return svc;
  }
})();
