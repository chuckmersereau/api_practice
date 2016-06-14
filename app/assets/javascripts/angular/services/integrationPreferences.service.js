angular.module('mpdxApp')
    .service('integrationPreferencesService', ['api', function (api) {
        var svc = this;
        this.data = {};
        this.loading = true;
        this.load = function () {
          api.call('get', 'preferences?integrations=true', {}, function(data) {
            svc.data = data.preferences;
            svc.loading = false;
          });
        };
        this.sync = function (service, success, error) {
          service = service.toLowerCase();
          if(service == 'mailchimp') {
            return $.get('/mail_chimp_accounts/sync', success).fail(error);
          }
          if(service == 'prayer letters') {
            return $.get('/prayer_letters_accounts/sync', success).fail(error);
          }
          if(service == 'pls') {
            return $.get('/pls_accounts/sync', success).fail(error);
          }
        }
        this.disconnect = function (service, success, error) {
          service = service.toLowerCase();
          if(service == 'mailchimp') {
            return $.ajax({ url: '/mail_chimp_accounts/' + svc.data.mail_chimp_account_id, type: 'DELETE', success: success, fail: error });
          }
          if(service == 'prayer letters') {
            return $.ajax({ url: '/prayer_letters_accounts/' + svc.data.prayer_letters_account_id, type: 'DELETE', success: success, fail: error });
          }
          if(service == 'pls') {
            return $.ajax({ url: '/pls_accounts/' + svc.data.pls_account_id, type: 'DELETE', success: success, fail: error });
          }
        }
        this.load();
    }]);
