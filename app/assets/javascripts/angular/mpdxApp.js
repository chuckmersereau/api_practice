angular
  .module('mpdxApp', [
    'ui.bootstrap',
    'LocalForageModule',
    'ngAnimate',
    'ngSanitize',
    'ngCsv',
    'isoCurrency',
    'ui.bootstrap',
    'ui.router'
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
      .state('preferences.tab', {
        url: '/:id',
        template: '<preferences></preferences>'
      })
      .state('notifications', {
        url: '/notifications',
        template: '<notification-preferences></notification-preferences>'
      })
      .state('integrations', {
        url: '/settings/integrations',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('integrations.tab', {
        url: '/:id',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('networks', {
        url: '/accounts',
        template: '<network-preferences></network-preferences>'
      })
      .state('networks.tab', {
        url: '/:id',
        template: '<network-preferences></network-preferences>'
      });
    $locationProvider.html5Mode({
      enabled: true,
      rewriteLinks: false
    }).hashPrefix('!');
  });
