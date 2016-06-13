(function(){
    angular
        .module('mpdxApp')
        .component('preferencesSidebar', {
            controller: sidebarController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/sidebar.html',
            bindings: {}
        });
    sidebarController.$inject = ['api'];
    function sidebarController(api) {
        var vm = this;
    }
})();
