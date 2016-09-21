(function(){
  angular
    .module('mpdxApp')
    .component('accountListPreferences', {
      controller: accountListPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/account_lists.html',
      bindings: {}
    });
  accountListPreferencesController.$inject = ['preferences.accountsService'];
  function accountListPreferencesController(accountsService) {
    var vm = this;
    vm.preferences = accountsService;
  }
})();
