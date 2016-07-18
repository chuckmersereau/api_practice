(function(){
  angular
    .module('mpdxApp')
    .component('preferences', {
      controller: preferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/index.html',
      bindings: {}
    }).config(preferencesRoute);

  preferencesRoute.$inject = ['$stateProvider'];
  function preferencesRoute($stateProvider) {
    $stateProvider
      .state('preferences', {
        title: 'Preferences',
        url: '/preferences',
        template: '<preferences></preferences>'
      });
  }

  preferencesController.$inject = [];
  function preferencesController() {
  }
})();
