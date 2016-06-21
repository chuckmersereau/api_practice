(function(){
    angular
        .module('mpdxApp')
        .component('notificationPreferences', {
            controller: notificationPreferencesController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/notifications.html',
            bindings: {}
        });
    notificationPreferencesController.$inject = ['notificationPreferencesService', 'alertsService'];
    function notificationPreferencesController(notificationPreferencesService, alertsService) {
      var vm = this;
      vm.preferences = notificationPreferencesService;
      vm.alerts = alertsService;
      vm.saving = false;
      vm.save = function () {
        vm.saving = true;
        vm.preferences.save(function success(data) {
          vm.alerts.addAlert('Notifications saved successfully', 'success');
          vm.saving = false;
          vm.saving = false;
        }, function error(data) {
          $.each(data.errors, function (index, value) { vm.alerts.addAlert(value, 'danger'); });
          vm.saving = false;
        });
      }
    }
})();
