
(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('preferences.importsService', importsService);

  importsService.$inject = ['$rootScope', 'api'];

  function importsService($rootScope, api) {
    var svc = {};
    svc.data = {};
    svc.loading = true;
    svc.default_google_contact_import = {
      source: 'google',
      source_account_id: null,
      import_by_group: 'false',
      override: 'false',
      groups: [],
      group_tags: {},
      tags: []
    };
    svc.google_contact_import = null;
    svc.selected_account = null;

    svc.load = function () {
      svc.loading = true;
      api.call('get', 'preferences/imports', {}, function(data) {
        svc.data = data.preferences;
        svc.loading = false;
        if (svc.data.google_accounts.length == 1) {
          svc.selected_account = svc.data.google_accounts[0];
          svc.selectedAccountUpdated(svc.selected_account);
        }
      });
    };

    svc.selectedAccountUpdated = function (account) {
      svc.google_contact_import = angular.copy(svc.default_google_contact_import);
      if (angular.isDefined(account) && account !== null) {
        svc.google_contact_import.source_account_id = account.id;
        angular.forEach(account.contact_groups, function(group) {
          svc.google_contact_import.group_tags[group.id] = [{ text: group.tag }];
        });
      }
    };

    svc.saveGoogleImport = function (success, error) {
      var data = angular.copy(svc.google_contact_import);
      if (angular.isDefined(data) && data !== null) {
        for(var key in data.group_tags) {
          if(data.group_tags.hasOwnProperty(key)) {
            data.group_tags[key] = data.group_tags[key].map(function(tag_arr) {
              return tag_arr.text;
            });
          }
        }
        data.tags = data.tags.map(function(tag) {
          return tag.text;
        });
        api.call('post', 'preferences/imports', { import: data }, function() {
          svc.selected_account = null;
          if (svc.data.google_accounts.length == 1) {
            svc.selected_account = svc.data.google_accounts[0];
            svc.selectedAccountUpdated(svc.selected_account);
          }
          svc.selectedAccountUpdated(svc.selected_account);
          success();
        }, error);
      }
    };

    svc.selected_account_watcher = $rootScope.$watch(function() {
      return svc.selected_account;
    }, svc.selectedAccountUpdated);

    svc.load();
    return svc;
  }
})();
