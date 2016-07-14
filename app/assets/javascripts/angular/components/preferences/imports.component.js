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
    vm.save = function () {
      vm.saving = true;
      vm.preferences.save(function success() {
        vm.alerts.addAlert('Notifications saved successfully', 'success');
        vm.saving = false;
        vm.saving = false;
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    };

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.imports', {}, { notify: false });
      } else {
        vm.tabId = service;
        $state.go('preferences.imports.tab', { id: service }, { notify: false });
      }
    };

    vm.tabSelected = function(service) {
      return vm.tabId == service;
    };

    vm.checkAllGoogleContactGroups = function() {
      vm.preferences.google_contact_import.import.groups = vm.preferences.selected_account.contact_groups.map(function(item) { return item.id; });
    };

    vm.uncheckAllGoogleContactGroups = function() {
      vm.preferences.google_contact_import.import.groups = [];
    };

    vm.loadTags = function(query) {
      return $filter('filter')(vm.preferences.data.tags, { text: query });
    };

    if ($stateParams.id) {
      vm.setTab($stateParams.id);
    }
  }
})();
