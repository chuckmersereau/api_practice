(function(){
  angular
    .module('mpdxApp')
    .component('accountPreferences', {
      controller: accountPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts.html',
      bindings: {}
    });
  accountPreferencesController.$inject = ['preferences.accountsService'];
  function accountPreferencesController(accountsService) {
    var vm = this;
    vm.preferences = accountsService;
  }
})();
