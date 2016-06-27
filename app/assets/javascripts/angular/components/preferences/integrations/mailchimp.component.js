(function(){
  angular
    .module('mpdxApp')
    .component('mailchimpIntegrationPreferences', {
      controller: MailchimpIntegrationPreferencesController,
      controllerAs: 'vm',
      templateUrl: '/templates/preferences/integrations/mailchimp.html',
      bindings: {
        'state': '='
      }
    });
  MailchimpIntegrationPreferencesController.$inject = ['$scope', 'preferences.integrations.mailchimpService', 'alertsService'];
  function MailchimpIntegrationPreferencesController($scope, mailchimpService, alertsService) {
    var vm = this;
    vm.preferences = mailchimpService;
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

    vm.sync = function() {
      vm.saving = true;
      vm.preferences.sync(function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX is now syncing your newsletter recipients with Mailchimp', 'success');
      }, function error() {
        vm.saving = false;
        vm.alerts.addAlert("MPDX couldn't save your configuration changes for Mailchimp", 'danger');
      });
    };

    vm.disconnect = function() {
      vm.saving = true;
      vm.preferences.disconnect(function success() {
        vm.saving = false;
        vm.alerts.addAlert('MPDX removed your integration with MailChimp', 'success');
        vm.preferences.load();
      }, function error() {
        vm.alerts.addAlert("MPDX couldn't save your configuration changes for MailChimp", 'danger');
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
