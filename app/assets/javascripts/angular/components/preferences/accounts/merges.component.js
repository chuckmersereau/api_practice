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

    vm.merge = function() {
      vm.saving = true;
      vm.preferences.create(function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX merged your account successfully', 'success');
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't merge your account", 'danger');
        vm.saving = false;
      });
    };
  }
})();
