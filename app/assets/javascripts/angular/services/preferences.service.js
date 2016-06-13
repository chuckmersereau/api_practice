angular.module('mpdxApp')
    .service('preferencesService', ['api', function (api) {
        var svc = this;
        this.data = {};
        this.load = function () {
          api.call('get', 'preferences?all=true', {}, function(data) {
            svc.data = data.preferences;
          });
        };

        this.save = function(success, error) {
          api.call('put', 'preferences/' + this.data.current_account_list_id,
                   { preference_set: this.data },
                   success,
                   error);
        }
        this.load();
    }]);
