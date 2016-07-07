angular.module('mpdxApp')
    .directive('replaceAvatar', function () {
        return {
            restrict: 'A',
            controller: function ($scope, $uibModal, api, state) {

              $scope.replaceFacebookLink = function(contactId, personId){
                $uibModal.open({
                  templateUrl: '/templates/components/contacts/editFacebookUrl.html',
                  controller: function($scope, $uibModalInstance){
                    $scope.facebookUrl = '';

                    $scope.cancel = function () {
                      $uibModalInstance.dismiss();
                    };

                    $scope.save = function () {
                      //console.log('sve');
                      $uibModalInstance.close($scope.facebookUrl);
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
                  api.call('put', 'contacts/' + contactId + '?account_list_id=' + state.current_account_list_id, obj, function(){
                    location.reload();
                  });
                });
              };
            }
        };
    });
