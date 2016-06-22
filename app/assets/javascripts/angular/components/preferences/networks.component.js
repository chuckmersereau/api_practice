(function(){
  angular
    .module('mpdxApp')
    .component('networkPreferences', {
      controller: networkPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/networks.html',
      bindings: {}
    });
  networkPreferencesController.$inject = ['$state', '$stateParams', 'networkPreferencesService', 'alertsService'];
  function networkPreferencesController($state, $stateParams, networkPreferencesService, alertsService) {
    var vm = this;
    vm.preferences = networkPreferencesService;
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
        $state.go('preferences', {}, { notify: false })
      } else {
        vm.tabId = service;
        $state.go('preferences.tab', { id: service }, { notify: false })
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
