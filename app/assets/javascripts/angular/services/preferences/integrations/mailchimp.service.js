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
    svc.load = function () {
      api.call('get', 'preferences/integrations/mailchimp', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };
    svc.load();

    return svc;
  }
})();
