(function(){
  angular
    .module('mpdxApp')
    .component('importPreferences', {
      controller: importPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/imports.html',
      bindings: {}
    });
  importPreferencesController.$inject = ['$filter', '$state', '$stateParams', 'preferences.importsService', 'alertsService'];
  function importPreferencesController($filter, $state, $stateParams, importsService, alertsService) {
    var vm = this;
    vm.preferences = importsService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.tabId = '';

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.imports', {}, { notify: false });
      } else {
        vm.tabId = service;
        if (service == 'google') {
          vm.preferences.load();
        }
        $state.go('preferences.imports.tab', { id: service }, { notify: false });
      }
    };

    vm.tabSelected = function(service) {
      return vm.tabId == service;
    };

    vm.loadTags = function(query) {
      return $filter('filter')(vm.preferences.data.tags, { text: query });
    };

    vm.checkAllGoogleContactGroups = function() {
      vm.preferences.google_contact_import.groups = vm.preferences.selected_account.contact_groups.map(function(item) { return item.id; });
    };

    vm.uncheckAllGoogleContactGroups = function() {
      vm.preferences.google_contact_import.groups = [];
    };

    vm.saveGoogleImport = function () {
      vm.saving = true;
      vm.preferences.saveGoogleImport(function success() {
        vm.alerts.addAlert('MPDx is importing contacts from your Google Account', 'success');
        vm.setTab('');
        vm.saving = false;
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    };

    if ($stateParams.id) {
      vm.setTab($stateParams.id);
    }
  }
})();
