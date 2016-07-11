(function(){
  angular
    .module('mpdxApp')
    .component('accountPreferences', {
      controller: accountPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts.html',
      bindings: {}
    });
  accountPreferencesController.$inject = ['$state', '$stateParams', 'alertsService'];
  function accountPreferencesController($state, $stateParams) {
    var vm = this;

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.accounts', {}, { notify: false })
      } else {
        vm.tabId = service;
        $state.go('preferences.accounts.tab', { id: service }, { notify: false })
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
