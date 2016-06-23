(function(){
  angular
    .module('mpdxApp')
    .component('networkPreferences', {
      controller: networkPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/networks.html',
      bindings: {}
    });
  networkPreferencesController.$inject = ['$state', '$stateParams', 'preferences.networksService', 'alertsService'];
  function networkPreferencesController($state, $stateParams, networksService, alertsService) {
    var vm = this;
    vm.preferences = networksService;
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
    }

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.networks', {}, { notify: false })
      } else {
        vm.tabId = service;
        $state.go('preferences.networks.tab', { id: service }, { notify: false })
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
