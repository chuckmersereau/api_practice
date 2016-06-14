angular.module('mpdxApp')
    .service('notificationPreferencesService', ['api', function (api) {
        var svc = this;
        this.data = {};
        this.loading = true;
        this.load = function () {
          api.call('get', 'preferences?notifications=true', {}, function(data) {
            svc.data = data.preferences;
            svc.loading = false;
          });
        };

        this.toggleNotification = function (field_name, notification_type) {
          var index = this.data[field_name].actions.indexOf(notification_type);
          if (index === -1) {
              this.data[field_name].actions.push(notification_type);
          } else {
              this.data[field_name].actions.splice(index, 1);
          }
        }

        this.save = function(success, error) {
          api.call('put', 'preferences/' + this.data.current_account_list_id,
                   { preference_set: this.data },
                   success,
                   error);
        }

        this.load();
    }]);
