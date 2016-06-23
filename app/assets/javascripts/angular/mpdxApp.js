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
      .state('preferences.integrations.configure-mailchimp', {
        url: '/configuration/mailchimp',
        template: '<integration-mailchimp-preferences></integration-mailchimp-preferences>'
      })
      .state('preferences.integrations.tab', {
        url: '/:id',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('preferences.networks', {
        url: '/networks',
        template: '<network-preferences></network-preferences>'
      })
      .state('preferences.networks.tab', {
        url: '/:id',
        template: '<network-preferences></network-preferences>'
      });
    $locationProvider.html5Mode({
      enabled: true,
      rewriteLinks: false
    }).hashPrefix('!');
  });
