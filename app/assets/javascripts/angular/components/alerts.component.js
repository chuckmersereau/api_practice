(function(){
    angular
        .module('mpdxApp')
        .component('alerts', {
            controller: alertsController,
            controllerAs: 'vm',
            templateUrl: '/templates/alerts.html',
            bindings: {}
        });
    alertsController.$inject = ['alertsService'];
    function alertsController(alertsService) {
      var vm = this;
      vm.alerts = alertsService;
      vm.removeAlert = function(alert) { this.alerts.removeAlert(alert) };
    }
})();
