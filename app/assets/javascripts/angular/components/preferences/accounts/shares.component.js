(function(){
  angular
    .module('mpdxApp')
    .component('sharePreferences', {
      controller: sharePreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts/shares.html',
      bindings: {}
    });
  sharePreferencesController.$inject = ['$state', '$stateParams', 'preferences.accounts.invitesService', 'preferences.accounts.usersService', 'alertsService'];
  function sharePreferencesController($state, $stateParams, invitesService, usersService, alertsService) {
    var vm = this;
    vm.invitePreferences = invitesService;
    vm.userPreferences = usersService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.inviteEmail = '';

    vm.cancelInvite = function(id) {
      vm.saving = true;
      vm.invitePreferences.destroy(id, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX removed the invite successfully', 'info');
        vm.invitePreferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't remove the invite", 'danger');
        vm.saving = false;
      });
    };

    vm.removeUser = function(id) {
      vm.saving = true;
      vm.userPreferences.destroy(id, function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX removed the user successfully', 'info');
        vm.userPreferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't remove the user", 'danger');
        vm.saving = false;
      });
    };
  }
})();
