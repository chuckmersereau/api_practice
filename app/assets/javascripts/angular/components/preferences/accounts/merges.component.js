(function(){
  angular
    .module('mpdxApp')
    .component('mergePreferences', {
      controller: mergePreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts/merges.html',
      bindings: {}
    });
  mergePreferencesController.$inject = ['$state', '$stateParams', 'preferences.accounts.mergesService', 'alertsService'];
  function mergePreferencesController($state, $stateParams, mergesService, alertsService) {
    var vm = this;
    vm.preferences = mergesService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.email = '';

    vm.merge = function() {
      vm.saving = true;
      vm.preferences.create(vm.email, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX sent an merge to ' + vm.email, 'success');
        vm.email = '';
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't send an merge (check to see if email address is valid)", 'danger');
        vm.saving = false;
      });
    };
  }
})();
