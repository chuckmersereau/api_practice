(function(){
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
    ]).config(function($locationProvider) {
      $locationProvider.html5Mode({
        enabled: true,
        rewriteLinks: false
      }).hashPrefix('!');
    });
})();
