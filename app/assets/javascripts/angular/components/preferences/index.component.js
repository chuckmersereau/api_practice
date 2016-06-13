(function(){
    angular
        .module('mpdxApp')
        .component('preferences', {
            controller: indexController,
            controllerAs: 'vm',
            templateUrl: '/templates/preferences/index.html',
            bindings: {}
        });
    indexController.$inject = ['preferencesService'];
    function indexController(preferencesService) {
      this.preferences = preferencesService;

      this.save = function () {
        $("button[type=submit]").prop('disabled', true).children('i.hidden').removeClass('hidden');
        $('#preferences_success').addClass('hidden');
        $('#preferences_error').addClass('hidden');
        $('#preferences_error ul').html('');
        this.preferences.save(function success(data) {
          $("button[type=submit]").prop('disabled', false).children('i').addClass('hidden');
          $('.collapse.in').collapse('hide');
          $('#preferences_success').removeClass('hidden');
        }, function error(data) {
          $("button[type=submit]").prop('disabled', false).children('i').addClass('hidden');
          $.each(data.errors, function (index, value) {
            $('#preferences_error ul').append('<li>'+ value +'</li>');
          });
          $('#preferences_error').removeClass('hidden');
        });
      }
    }
})();
