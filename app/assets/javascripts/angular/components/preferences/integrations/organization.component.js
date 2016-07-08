(function(){
  angular
    .module('mpdxApp')
    .component('organizationIntegrationPreferences', {
      controller: OrganizationIntegrationPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/integrations/organization.html',
      bindings: {}
    });
  OrganizationIntegrationPreferencesController.$inject = ['$scope', 'preferences.integrations.organizationService', 'alertsService'];
  function OrganizationIntegrationPreferencesController($scope, organizationService, alertsService) {
    var vm = this;
    vm.preferences = organizationService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.page = 'org_list';
    vm.selected = null;
    vm.username = null;
    vm.password = null;

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

    vm.createAccount = function() {
      vm.saving = true;
      vm.preferences.createAccount(vm.username, vm.password, vm.selected.id,
        function success() {
        vm.saving = false;
        vm.preferences.load();
        vm.revert();
        vm.alerts.addAlert('MPDX added your organization account', 'success');
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    };

    vm.updateAccount = function() {
      vm.saving = true;
      vm.preferences.updateAccount(vm.username, vm.password, vm.selected.id,
        function success() {
        vm.saving = false;
        vm.preferences.load();
        vm.revert();
        vm.alerts.addAlert('MPDX updated your organization account', 'success');
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    };

    vm.editAccount = function(account) {
      vm.page = 'edit_account';
      vm.selected = account;
      vm.username = account.username;
    }

    vm.revert = function() {
      vm.page = 'org_list';
      vm.selected = null;
      vm.username = null;
      vm.password = null;
    }
  }
})();
