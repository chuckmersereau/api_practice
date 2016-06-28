(function(){
  angular
    .module('mpdxApp')
    .component('integrationPreferences', {
      controller: integrationPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/integrations.html',
      bindings: {}
    });
  integrationPreferencesController.$inject = ['$window', '$state', '$stateParams', 'preferences.integrationsService', 'alertsService'];
  function integrationPreferencesController($window, $state, $stateParams, integrationsService, alertsService) {
    var vm = this;
    vm.preferences = integrationsService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.tabId = '';
    vm.$state = $state;
    vm.mailchimpAccStatus = 'disabled';
    vm.sync = function(service) {
      vm.saving = true;
      vm.service = service;
      vm.preferences.sync(service, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX is now syncing your newsletter recipients with ' + vm.service, 'success');
      }, function error() {
        vm.saving = false;
        vm.alerts.addAlert("MPDX couldn't save your configuration changes for " + vm.service, 'danger');
      });
    };

    vm.disconnect = function(service, id) {
      vm.saving = true;
      vm.service = service;
      vm.preferences.disconnect(service, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX removed your integration with ' + vm.service, 'success');
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't save your configuration changes for " + vm.service, 'danger');
        vm.saving = false;
      }, id);
    };

    vm.reload = function() {
      vm.preferences.load();
    }

    $window.openerCallback = vm.reload;

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.integrations', {}, { notify: false })
      } else {
        vm.tabId = service;
        $state.go('preferences.integrations.tab', { id: service }, { notify: false })
      }
    };

    vm.tabSelected = function(service) {
      return vm.tabId == service;
    };

    if ($stateParams.id) {
      vm.setTab($stateParams.id);
    }
  }
})();
