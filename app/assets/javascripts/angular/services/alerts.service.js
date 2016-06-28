(function() {
  'use strict';

  angular
    .module('mpdxApp')
    .factory('alertsService', alertsService);

  alertsService.$inject = ['$timeout'];

  function alertsService($timeout) {
    var svc = {};
    svc.alerts = [];
    svc.timeout = null;

    svc.removeAlert = function (alert) {
      var index = svc.alerts.indexOf(alert);
      svc.alerts.splice(index, 1);
    };

    svc.addAlert = function (message, type, displayTime) {
      svc.alerts = [];
      displayTime = angular.isDefined(displayTime) ? displayTime : 5000;
      var alert = { message: message, type: 'alert-' + type };
      svc.alerts.push(alert);
      if (svc.timeout !== null) {
        $timeout.cancel(svc.timeout);
      }
      svc.timeout = $timeout(function () { svc.removeAlert(alert); }, displayTime);
    };

    return svc;
  }
  })();
