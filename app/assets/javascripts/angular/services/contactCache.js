angular.module('mpdxApp')
    .service('contactCache', function ($cacheFactory, $rootScope, $http) {
        var cache = $cacheFactory('contact');

        var path = function (id) {
            return '/api/v1/contacts/' + (id || '');
        };

        var checkCache = function (path, callback) {
            var cachedContact = cache.get(path);
            if (angular.isDefined(cachedContact)) {
                callback(cachedContact, path);
            } else {
                $http.get(path).then(function (response) {
                    cache.put(path, response.data);
                    callback(response.data, path);
                });
            }
        };

        this.get = function (id, callback) {
            checkCache(path(id), function (contact) {
                if(_.isFunction(callback)) {
                    callback(contact);
                }
            });
        };

        this.getFromCache = function(id){
            return cache.get(path(id)) || undefined;
        };

        this.update = function (id, contact) {
            cache.put(path(id), contact);
        };
    });
