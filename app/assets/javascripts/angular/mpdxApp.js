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
    'localytics.directives',
    'checklist-model',
    'ngTagsInput'
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
        title: 'Preferences',
        url: '/preferences',
        template: '<preferences></preferences>'
      })
      .state('preferences.personal', {
        title: 'Preferences',
        url: '/personal',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('preferences.personal.tab', {
        url: '/:id',
        template: '<personal-preferences></personal-preferences>'
      })
      .state('preferences.notifications', {
        title: 'Notifications',
        url: '/notifications',
        template: '<notification-preferences></notification-preferences>'
      })
      .state('preferences.integrations', {
        title: 'Connect Services',
        url: '/integrations',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('preferences.integrations.tab', {
        url: '/:id',
        template: '<integration-preferences></integration-preferences>'
      })
      .state('preferences.accounts', {
        title: 'Manage Accounts',
        url: '/accounts',
        template: '<account-preferences></account-preferences>'
      })
      .state('preferences.accounts.tab', {
        url: '/:id',
        template: '<account-preferences></account-preferences>'
      })
      .state('preferences.imports', {
        title: 'Import Contacts',
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
