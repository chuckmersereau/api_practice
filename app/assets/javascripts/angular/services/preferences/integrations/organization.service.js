(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.integrations.organizationService', organizationService);

  organizationService.$inject = ['api'];

  function organizationService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.state = 'disabled';
    svc.load = function () {
      api.call('get', 'preferences/integrations/organization_accounts', {}, function(data) {
        svc.data.organization_accounts = data.organization_accounts;
        svc.updateState();
        svc.loading = false;
      });
    };

    svc.save = function(success, error) {
      api.call('put', 'preferences/integrations/organization_account', { organization: this.data },
        function (data) {
          svc.data = data.organizations;
          svc.updateState();
          success(data);
        },
        error);
    };

    svc.disconnect = function (id, success, error) {
      api.call('delete', 'preferences/integrations/organization_accounts/' + id, { }, success, error);
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
