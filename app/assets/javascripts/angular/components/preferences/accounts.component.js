(function(){
  angular
    .module('mpdxApp')
    .component('accountPreferences', {
      controller: accountPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts.html',
      bindings: {}
    });
  accountPreferencesController.$inject = [];
  function accountPreferencesController() {
    var vm = this;
  }
})();
