angular.module('mpdxApp')
    .service('urlParameter', function ($window) {
        this.get = function(name) {
            return decodeURIComponent((new RegExp('[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)').exec($window.location.search)||[,""])[1].replace(/\+/g, '%20'))||null
        };
    });
