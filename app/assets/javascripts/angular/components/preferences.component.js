(function(){
  angular
    .module('mpdxApp')
    .component('preferences', {
      controller: preferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/index.html',
      bindings: {}
    });
  preferencesController.$inject = [];
  function preferencesController() {
  }
})();
