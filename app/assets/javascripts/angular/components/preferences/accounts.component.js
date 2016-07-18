(function(){
  angular
    .module('mpdxApp')
    .component('accountPreferences', {
      controller: accountPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/accounts.html',
      bindings: {}
    }).config(accountPreferencesRoute);

  accountPreferencesRoute.$inject = ['$stateProvider'];
  function accountPreferencesRoute($stateProvider) {
    $stateProvider
      .state('preferences.accounts', {
        title: 'Manage Accounts',
        url: '/accounts',
        template: '<account-preferences></account-preferences>'
      })
      .state('preferences.accounts.tab', {
        title: 'Manage Accounts',
        url: '/:id',
        template: '<account-preferences></account-preferences>'
      });
  }

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
