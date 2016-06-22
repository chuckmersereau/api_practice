(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferencesService', preferencesService);

  preferencesService.$inject = ['api'];

  function preferencesService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.load = function () {
      api.call('get', 'preferences?base=true', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };

    svc.save = function(success, error) {
      api.call('put', 'preferences/' + this.data.current_account_list_id,
        { preference_set: this.data },
        success,
        error);
    }

    svc.load();

    return svc;
  }
})();
