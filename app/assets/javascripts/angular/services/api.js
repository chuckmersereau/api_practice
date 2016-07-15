(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('api', api);

  api.$inject = ['$http', '$cacheFactory'];

  function api($http, $cacheFactory) {
    var svc = this;
    svc.apiUrl = '/api/v1/';
    svc.apiCache = $cacheFactory('api');
    svc.account_list_id = null;

    // This function supports both callbacks (successFn, errorFn) and returns a promise
    // It would be preferred to use promises in the future
    svc.call = function (method, url, data, successFn, errorFn, cache, params) {
        if(cache === true){
            var cachedData = apiCache.get(url);
            if (angular.isDefined(cachedData)) {
                if(_.isFunction(successFn)) {
                    successFn(cachedData, 304);
                }
                return $q.resolve(cachedData);
            }
        }
        if (data === undefined) {
          data = {};
        }
        if (svc.account_list_id !== null) {
          data.account_list_id = svc.account_list_id;
        }
        if (method === 'get' || method === 'delete') {
          params = data;
        }
        return $http({
            method: method,
            url: svc.apiUrl + url,
            data: data,
            params: params,
            cache: false,
            timeout: 50000
        })
            .then(function(response) {
                if(_.isFunction(successFn)){
                    successFn(response.data, response.status);
                }
                if(cache === true){
                    svc.apiCache.put(url, response.data);
                }
                return response.data;
            }, function(response) {
                $log.error('API ERROR:', response.status, response.data);
                if(_.isFunction(errorFn)){
                    errorFn(response);
                }
                return $q.reject(response);
            });
    };

    svc.get = function (url, data, successFn, errorFn, cache) {
        return svc.call('get', url, data, successFn, errorFn, cache);
    };
    svc.post = function (url, data, successFn, errorFn, cache) {
        return svc.call('post', url, data, successFn, errorFn, cache);
    };

    svc.encodeURLarray = function encodeURLarray(array){
        return _.map(array, encodeURIComponent);
    }

    return svc;
  }
})();
