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

    svc.call = function (method, url, data, successFn, errorFn, cache, params) {
        if(cache === true){
            var cachedData = svc.apiCache.get(url);
            if (angular.isDefined(cachedData)) {
                successFn(cachedData, 200);
                return;
            }
        }
        if (data === undefined) {
          data = {};
        }
        if (svc.account_list_id !== null) {
          data.account_list_id = svc.account_list_id;
        }
        if (method === 'get') {
          params = data;
        }
        return $http({
            method: method,
            url: svc.apiUrl + url,
            data: data,
            params: params,
            cache: false,
            timeout: 50000
        }).
            success(function(data, status) {
                if(_.isFunction(successFn)){
                    successFn(data, status);
                }
                if(cache === true){
                    svc.apiCache.put(url, data);
                }
            }).
            error(function(data, status) {
                console.log('API ERROR: ' + status);
                if(_.isFunction(errorFn)){
                    errorFn(data, status);
                }
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
