angular.module('mpdxApp')
    .directive('replaceAvatar', function () {
        return {
            restrict: 'A',
            template: '',
            controller: function ($scope, $modal, api) {

              $scope.replaceFacebookLink = function(contactId, personId, url){
                var contactObj;
                api.call('get', 'contacts/' + contactId, null, function(data){
                  contactObj = data;
                });

                $modal.open({
                  templateUrl: '/templates/contacts/editFacebookUrl.html',
                  controller: function($scope, $modalInstance, facebookUrl){
                    $scope.facebookUrl = facebookUrl;

                    $scope.cancel = function () {
                      $modalInstance.dismiss();
                    };

                    $scope.save = function () {
                      $modalInstance.close($scope.facebookUrl);
                    };
                  },
                  resolve: {
                    facebookUrl: function () {
                      return url;
                    }
                  }
                }).result.then(function (facebookUrl) {
                  obj = {
                    contact: {
                      people_attributes: [{
                        id: contactObj.people[0]['id'],
                        facebook_accounts_attributes: {
                          1430848487081: { url: facebookUrl }
                        }
                      }]
                    }
                  }
                  api.call('put', 'contacts/' + contactId + '?account_list_id=' + window.current_account_list_id, obj);
                });
              };
            }
        };
    });
