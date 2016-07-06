angular.module('mpdxApp')
    .service('urlParameter', function ($location) {
        this.get = function(name) {
            return $location.search()[name];
        };
    });
