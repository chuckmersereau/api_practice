angular.module('mpdxApp')
    .factory('api', function ($rootScope, $http, $cacheFactory, _, $q, $log) {
        var apiUrl = '/api/v1/';
        var apiCache = $cacheFactory('api');

        var factory = {
            call: call,
            get: get,
            post: post,
            encodeURLarray: encodeURLarray
        };

        return factory;

        // This function supports both callbacks (successFn, errorFn) and returns a promise
        // It would be preferred to use promises in the future
        function call(method, url, data, successFn, errorFn, cache) {
            if(cache === true){
                var cachedData = apiCache.get(url);
                if (angular.isDefined(cachedData)) {
                    if(_.isFunction(successFn)) {
                        successFn(cachedData, 304);
                    }
                    return $q.resolve(cachedData);
                }
            }
            return $http({
                method: method,
                url: apiUrl + url,
                data: data,
                cache: false,
                timeout: 50000
            })
                .then(function(response) {
                    if(_.isFunction(successFn)){
                        successFn(response.data, response.status);
                    }
                    if(cache === true){
                        apiCache.put(url, response.data);
                    }
                    return response.data;
                }, function(response) {
                    $log.error('API ERROR:', response.status, response.data);
                    if(_.isFunction(errorFn)){
                        errorFn(response);
                    }
                    return $q.reject(response);
                });
        }

        function get(url, data, successFn, errorFn, cache) {
            return this.call('get', url, data, successFn, errorFn, cache);
        }

        function post(url, data, successFn, errorFn, cache) {
            return this.call('post', url, data, successFn, errorFn, cache);
        }

        function encodeURLarray(array){
            return _.map(array, encodeURIComponent);
        }
    });
