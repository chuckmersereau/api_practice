(function(){
    angular
        .module('mpdxApp')
        .component('integrationPreferences', {
            controller: integrationPreferencesController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/integrations.html',
            bindings: {}
        });
    integrationPreferencesController.$inject = ['integrationPreferencesService'];
    function integrationPreferencesController(integrationPreferencesService) {
      var vm = this;
      this.preferences = integrationPreferencesService;

      this.sync = function($event, service) {
        var $target = $($event.target);
        $target.addClass('disabled').children('i.hidden').removeClass('hidden');
        $('.integration-alerts').addClass('hidden');
        this.service = service;
        this.preferences.sync(service, function success(data) {
          $target.removeClass('disabled').children('i').addClass('hidden');
          $('#preferences_success').removeClass('hidden');
        }, function error(data) {
          $target.removeClass('disabled').children('i').addClass('hidden');
          $('#preferences_error').removeClass('hidden');
        });
      }

      this.disconnect = function($event, service) {
        var $target = $($event.target);
        $target.addClass('disabled').children('i.hidden').removeClass('hidden');
        $('.integration-alerts').addClass('hidden');
        this.service = service;
        this.preferences.disconnect(service, function success(data) {
          $target.removeClass('disabled').children('i').addClass('hidden');
          $('#preferences_deletion_success').removeClass('hidden');
          vm.preferences.load();
        }, function error(data) {
          $target.removeClass('disabled').children('i').addClass('hidden');
          $('#preferences_error').removeClass('hidden');
        });
      }
    }
})();
