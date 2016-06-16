(function(){
    angular
        .module('mpdxApp')
        .component('preferences', {
            controller: indexController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/index.html',
            bindings: {}
        });
    indexController.$inject = ['$scope', 'preferencesService', 'alertsService'];
    function indexController($scope, preferencesService, alertsService) {
      var vm = this;
      vm.preferences = preferencesService;
      vm.alerts = alertsService;
      vm.saving = false;
      vm.save = function () {
        vm.saving = true;
        vm.preferences.save(function success(data) {
          vm.alerts.addAlert('Preferences saved successfully', 'success');
          $('.collapse.in').collapse('hide');
          vm.saving = false;
        }, function error(data) {
          $.each(data.errors, function (index, value) { vm.alerts.addAlert(value, 'danger'); });
          vm.saving = false;
        });
      }

      vm.locale_string = '';
      $scope.$watch(
        'vm.preferences.data.locale',
        function (newValue) {
          vm.locale_string = $('#_locale option[value=' + newValue + ']').text();
        }
      )

      vm.default_account_string = '';
      $scope.$watch(
        'vm.preferences.data.default_account_list',
        function (newValue) {
          vm.default_account_string = $('#_default_account_list option[value=' + newValue + ']').text();
        }
      )

      vm.salary_organization_string = '';
      $scope.$watch(
        'vm.preferences.data.salary_organization_id',
        function (newValue) {
          vm.salary_organization_string = $('#salary_organization_id_ option[value=' + newValue + ']').text();
        }
      )
    }
})();
