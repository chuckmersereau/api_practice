(function(){
  angular
    .module('mpdxApp')
    .component('invitePreferences', {
      controller: invitePreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts/invites.html',
      bindings: {}
    });
  invitePreferencesController.$inject = ['$state', '$stateParams', 'preferences.accounts.invitesService', 'alertsService'];
  function invitePreferencesController($state, $stateParams, invitesService, alertsService) {
    var vm = this;
    vm.preferences = invitesService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.email = '';

    vm.sendInvite = function() {
      vm.saving = true;
      vm.preferences.create(vm.email, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX sent an invite to ' + vm.email, 'success');
        vm.email = '';
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't send an invite (check to see if email address is valid)", 'danger');
        vm.saving = false;
      });
    };
  }
})();
