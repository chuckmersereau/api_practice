angular
  .module('mpdxApp', [
    'ui.bootstrap',
    'LocalForageModule',
    'ngAnimate',
    'ngSanitize',
    'ngCsv',
    'isoCurrency',
    'ui.bootstrap',
    'ui.router',
    'localytics.directives'
  ]);

angular
  .module('mpdxApp')
  .run(function () {

  });

angular
  .module('mpdxApp')
  .config(function($locationProvider, $stateProvider) {
    $stateProvider
      .state('preferences', {
        url: '/preferences',
        template: '<preferences></preferences>'
      })
      .state('preferences.personal', {
        url: '/personal',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('preferences.personal.tab', {
        url: '/:id',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('preferences.notifications', {
        url: '/notifications',
        template: '<notification-preferences></notification-preferences>'
      })
      .state('preferences.integrations', {
        url: '/integrations',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('preferences.integrations.tab', {
        url: '/:id',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('preferences.imports', {
        url: '/imports',
        template: '<import-preferences></import-preferences>'
      })
      .state('preferences.imports.tab', {
        url: '/:id',
        template: '<import-preferences></import-preferences>'
      });
    $locationProvider.html5Mode({
      enabled: true,
      rewriteLinks: false
    }).hashPrefix('!');
  });
