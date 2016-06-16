angular.module('mpdxApp')
    .service('alertsService', ['$timeout', function ($timeout) {
        var svc = this;
        svc.alerts = [];
        
        svc.removeAlert = function (alert) {
            var index = svc.alerts.indexOf(alert);
            svc.alerts.splice(index, 1);
        }

        svc.addAlert = function (message, type = 'info', displayTime = 5000) {
          var alert = { message: message, type: 'alert-' + type }
          svc.alerts.push(alert);
          $timeout(function() { svc.removeAlert(alert) }, displayTime);
        }
    }]);
