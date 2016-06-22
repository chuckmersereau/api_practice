(function(){
    angular
      .module('mpdxApp')
      .component('preferencesSidebar', {
        controller: sidebarController,
        controllerAs: 'vm',
        templateUrl: '/templates/preferences/sidebar.html',
        bindings: {}
      });
    function sidebarController() {
    }
})();
