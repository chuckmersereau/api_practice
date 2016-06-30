(function(){
  angular
    .module('mpdxApp')
    .component('organizationIntegrationPreferences', {
      controller: OrganizationIntegrationPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/integrations/organization.html',
      bindings: {
        'state': '='
      }
    });
  OrganizationIntegrationPreferencesController.$inject = ['$scope', 'preferences.integrations.organizationService', 'alertsService'];
  function OrganizationIntegrationPreferencesController($scope, organizationService, alertsService) {
    var vm = this;
    vm.preferences = organizationService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.showSettings = false;

    vm.save = function () {
      vm.saving = true;
      vm.preferences.save(function success() {
        vm.alerts.addAlert('Preferences saved successfully', 'success');
        vm.saving = false;
        if (vm.preferences.data.primary_list_id != null) {
          vm.hide();
        }
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    };

    vm.hide = function () {
      vm.preferences.loading = true;
      vm.preferences.load();
      vm.showSettings = false;
    };

    vm.disconnect = function(id) {
      vm.saving = true;
      vm.preferences.disconnect(id,
        function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX removed your organization integration', 'success');
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't save your configuration changes for that organization", 'danger');
        vm.saving = false;
      });
    };

    $scope.$watch(function() {
      return vm.preferences.state;
    }, function() {
      vm.state = vm.preferences.state;
    } )
  }
})();
