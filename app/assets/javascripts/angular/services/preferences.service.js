angular.module('mpdxApp')
    .service('preferencesService', ['api', function (api) {
        var svc = this;
        this.data = {};
        this.loading = true;
        this.load = function () {
          api.call('get', 'preferences?base=true', {}, function(data) {
            svc.data = data.preferences;
            svc.loading = false;
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
