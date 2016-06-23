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
      .state('personal', {
        url: '/preferences/personal',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('personal.tab', {
        url: '/:id',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('notifications', {
        url: 'preferences/notifications',
        template: '<notification-preferences></notification-preferences>'
      })
      .state('integrations', {
        url: '/preferences/integrations',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('integrations.tab', {
        url: '/:id',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('integrations.mailchimp', {
        url: '/mailchimp/configuration',
        template: '<integration-mailchimp-preferences></integration-mailchimp-preferences>'
      })
      .state('networks', {
        url: '/preferences/networks',
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
