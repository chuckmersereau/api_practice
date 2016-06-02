(function() {
    angular
        .module('mpdxApp')
        .factory('twitterCldr', TwitterCldrFactory);

    TwitterCldrFactory.$inject = ['$window'];

    // This encapsulates the TwitterCldr constant so that we can use it in
    // Angular dependency injection.
    function TwitterCldrFactory($window) {
        return $window.TwitterCldr;
    }
})();
