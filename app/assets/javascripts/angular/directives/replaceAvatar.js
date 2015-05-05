angular.module('mpdxApp')
    .directive('replaceAvatar', function () {
        return {
            restrict: 'A',
            controller: function ($scope, $modal, api) {

              $scope.replaceFacebookLink = function(contactId, personId){
                $modal.open({
                  templateUrl: '/templates/contacts/editFacebookUrl.html',
                  controller: function($scope, $modalInstance){
                    $scope.facebookUrl = '';

                    $scope.cancel = function () {
                      $modalInstance.dismiss();
                    };

                    $scope.save = function () {
                      $modalInstance.close($scope.facebookUrl);
                    };
                  }
                }).result.then(function (facebookUrl) {
                  var obj = {
                    contact: {
                      people_attributes: [{
                        id: personId,
                        facebook_accounts_attributes: {
                          0: { url: facebookUrl }
                        }
                      }]
                    }
                  };
                  api.call('put', 'contacts/' + contactId + '?account_list_id=' + window.current_account_list_id, obj, function(){
                    location.reload();
                  });
                });
              };
            }
        };
    });
