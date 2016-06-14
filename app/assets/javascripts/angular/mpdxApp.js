angular
    .module('mpdxApp', [
        'ui.bootstrap',
        'LocalForageModule',
        'ngAnimate',
        'isoCurrency',
        'ui.router'
    ]);

angular
    .module('mpdxApp')
    .run(function () {

    });

angular
    .module('mpdxApp')
    .config(function($locationProvider, $stateProvider, $urlRouterProvider) {
      $urlRouterProvider.otherwise('/preferences');
      $stateProvider
        .state('preferences', {
          url: '/preferences',
          template: '<preferences></preferences>'
        })
      .state('notifications', {
        url: '/notifications',
        template: '<notification-preferences></notification-preferences>'
      });
      $('a').each(function(){
        $a = $(this);
        if ($a.is('[target]') || $a.is('[ui-sref]')){
        } else {
            $a.attr('target', '_self');
        }
      });
      $locationProvider.html5Mode(true).hashPrefix('!');
    });
