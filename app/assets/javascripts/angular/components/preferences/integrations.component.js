(function(){
    angular
        .module('mpdxApp')
        .component('integrationPreferences', {
            controller: integrationPreferencesController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/integrations.html',
            bindings: {}
        });
    integrationPreferencesController.$inject = ['integrationPreferencesService', 'alertsService'];
    function integrationPreferencesController(integrationPreferencesService, alertsService) {
      var vm = this;
      vm.preferences = integrationPreferencesService;
      vm.alerts = alertsService;
      vm.saving = false;

      vm.sync = function(service) {
        vm.saving = true;
        vm.service = service;
        vm.preferences.sync(service, function success(data) {
          vm.saving = false;
          vm.alerts.addAlert('MPDX is now syncing your newsletter recipients with ' + vm.service, 'success');
        }, function error(data) {
          vm.saving = false;
          vm.alerts.addAlert("MPDX couldn't save your configuration changes for " + vm.service, 'danger');
        });
      }

      vm.disconnect = function(service) {
        vm.saving = true;
        vm.service = service;
        vm.preferences.disconnect(service, function success(data) {
          vm.saving = false;
          vm.alerts.addAlert('MPDX removed your integration with ' + vm.service, 'success');
          vm.preferences.load();
        }, function error(data) {
          vm.alerts.addAlert("MPDX couldn't save your configuration changes for " + vm.service, 'danger');
          vm.saving = false;
        });
      }
    }
})();
