(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .directive('title', titleDirective);

  titleDirective.$inject = ['$rootScope', '$timeout'];

  function titleDirective($rootScope, $timeout) {
    return {
      link: function() {

        var listener = function(event, toState) {

          $timeout(function() {
            $rootScope.title = toState.title ? toState.title : '';
          });
        };

        var destroyCallback = $rootScope.$on('$stateChangeSuccess', listener);
        $rootScope.$on('$destroy', destroyCallback);
      }
    };
  }
})();
