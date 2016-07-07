angular.module('mpdxApp')
    .factory('contactCache', function ($cacheFactory, $rootScope, $http, _) {
        var cache = $cacheFactory('contact');

        var factory = {
            get: get,
            getFromCache: getFromCache,
            update: update
        };

        return factory;

        function path(id) {
            return '/api/v1/contacts/' + (id || '');
        }

        function checkCache(path, callback) {
            var cachedContact = cache.get(path);
            if (angular.isDefined(cachedContact)) {
                callback(cachedContact, path);
            } else {
                $http.get(path).success(function (contact) {
                    cache.put(path, contact);
                    callback(contact, path);
                });
            }
        }

        function get(id, callback) {
            checkCache(path(id), function (contact) {
                if(_.isFunction(callback)) {
                    callback(contact);
                }
            });
        }

        function getFromCache(id){
            return cache.get(path(id)) || undefined;
        }

        function update(id, contact) {
            cache.put(path(id), contact);
        }
    });