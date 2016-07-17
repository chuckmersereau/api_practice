(function(){
  angular
    .module('mpdxApp')
    .component('notificationPreferences', {
      controller: notificationPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/notifications.html',
      bindings: {}
    }).config(notificationPreferencesRoute);

  notificationPreferencesRoute.$inject = ['$stateProvider'];
  function notificationPreferencesRoute($stateProvider) {
    $stateProvider
      .state('preferences.notifications', {
        title: 'Notifications',
        url: '/notifications',
        template: '<notification-preferences></notification-preferences>'
      });
  }

  notificationPreferencesController.$inject = ['preferences.notificationsService', 'alertsService'];
  function notificationPreferencesController(notificationsService, alertsService) {
    var vm = this;
    vm.preferences = notificationsService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.save = function () {
      vm.saving = true;
      vm.preferences.save(function success() {
        vm.alerts.addAlert('Notifications saved successfully', 'success');
        vm.saving = false;
        vm.saving = false;
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    }
  }
})();
