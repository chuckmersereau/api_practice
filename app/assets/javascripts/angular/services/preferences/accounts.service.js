
(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.networksService', networksService);

  networksService.$inject = ['api'];

  function networksService(api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.load = function () {
      api.call('get', 'preferences?accounts=true', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
      });
    };
    svc.load();
    return svc;
  }
})();
