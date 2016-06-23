(function(){
  angular
    .module('mpdxApp')
    .component('personalPreferences', {
      controller: personalPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/personal.html',
      bindings: {}
    });
  personalPreferencesController.$inject = ['$state', '$stateParams', '$scope', 'preferences.personalService', 'alertsService'];
  function personalPreferencesController($state, $stateParams, $scope, personalService, alertsService) {
    var vm = this;
    vm.preferences = personalService;
    vm.alerts = alertsService;
    vm.saving = false;
    vm.tabId = '';

    vm.save = function () {
      vm.saving = true;
      vm.preferences.save(function success() {
        vm.alerts.addAlert('Preferences saved successfully', 'success');
        vm.setTab('');
        vm.saving = false;
      }, function error(data) {
        angular.forEach(data.errors, function(value) {
          vm.alerts.addAlert(value, 'danger');
        });
        vm.saving = false;
      });
    }

    vm.locale_string = '';
    $scope.$watch(
      'vm.preferences.data.locale',
      function (newValue) {
        vm.locale_string = angular.element('#_locale option[value=' + newValue + ']').text();
      }
    )

    vm.default_account_string = '';
    $scope.$watch(
      'vm.preferences.data.default_account_list',
      function (newValue) {
        vm.default_account_string = angular.element('#_default_account_list option[value=' + newValue + ']').text();
      }
    )

    vm.salary_organization_string = '';
    $scope.$watch(
      'vm.preferences.data.salary_organization_id',
      function (newValue) {
        vm.salary_organization_string = angular.element('#salary_organization_id_ option[value=' + newValue + ']').text();
      }
    )

    vm.setTab = function(service) {
      if (service == '' || vm.tabId == service) {
        vm.tabId = '';
        $state.go('preferences.personal', {}, { notify: false })
      } else {
        vm.tabId = service;
        $state.go('preferences.personal.tab', { id: service }, { notify: false })
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
