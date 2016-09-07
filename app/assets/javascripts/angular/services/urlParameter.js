angular.module('mpdxApp')
    .factory('urlParameter', function ($window) {
        var factory = {
            get: get
        };

        return factory;

        function get(name) {
            return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec($window.location.search)||[,""])[1].replace(/\+/g, '%20')) || null;
        }
    });
