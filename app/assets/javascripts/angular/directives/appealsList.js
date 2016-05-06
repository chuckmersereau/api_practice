angular.module('mpdxApp')
    .directive('appealsList', function () {
        return {
            restrict: 'E',
            templateUrl: '/templates/appeals/list.html',
            controller: ['$scope', '$uibModal', 'api', 'state', function ($scope, $uibModal, api, state) {
                var refreshAppeals = function(callback){
                    api.call('get','appeals?account_list_id=' + (state.current_account_list_id || ''), {}, function(data) {
                        $scope.appeals = data.appeals;
                      if(_.isFunction(callback)){
                        callback(data);
                      }
                    });
                };
                refreshAppeals();

                function donationAggregates(donations) {
                  var amounts = _.chain(donations)
                    .map(function(d) { return d.appeal_amount || d.amount })
                    .reject(function(n) {return !n})
                    .value();
                  var sum = _.sum(amounts);
                  return {sum: sum, average: sum/amounts.length};
                }

                $scope.donationAggregates = function(donations){
                  return donationAggregates(donations);
                };

                $scope.percentComplete = function(appeal){
                  goal = Number(appeal.amount);
                  if(goal === 0){
                    return 0;
                  }
                  return Math.round(($scope.donationAggregates(appeal.donations).sum / goal) * 100);
                };

                $scope.progressClass = function(appeal) {
                    var percent = $scope.percentComplete(appeal);
                    if(percent < 33) {
                        return 'progress-red';
                    }
                    if(percent < 66) {
                        return 'progress-yellow';
                    }
                    return 'progress-green';
                };

                $scope.editAppeal = function(id) {
                    window.location = '/appeals/' + id + '?firstShow';
                };

                $scope.newAppeal = function(){
                    var modalInstance = $uibModal.open({
                        templateUrl: '/templates/appeals/wizard.html',
                        size: 'lg',
                        controller: ['$scope', '$uibModalInstance', function($scope, $uibModalInstance){
                            $scope.contactStatuses = window.railsConstants.contact.ACTIVE_STATUSES;

                            defaultValidStatuses = {};
                            angular.forEach($scope.contactStatuses, function(status){
                                defaultValidStatuses[status] = true;
                            });

                            $scope.goal = {
                              adminPercent: 12
                            };

                            $scope.appeal = {
                              validStatus: defaultValidStatuses,
                              validTags: {},
                              exclude: {
                                  specialGift3months: true,
                                  joinedTeam3months: true,
                                  increasedGiving3months: true,
                                  stoppedGiving2months: true,
                                  doNotAskAppeals: true
                              }
                            };
                            api.call('get', 'contacts/tags?account_list_id=' + (state.current_account_list_id || ''), null, function(data) {
                              $scope.contactTags = data.tags.sort();
                            }, null, true);

                            $scope.cancel = function () {
                                $uibModalInstance.dismiss('cancel');
                            };

                            $scope.save = function () {
                                $uibModalInstance.close($scope.appeal);
                            };

                          $scope.calculateGoal = function(goal){
                            var adminPercent = Number(goal.adminPercent) / 100 + 1;
                            $scope.appeal.amount = Math.round((Number(goal.initial) + Number(goal.letterCost)) * adminPercent * 100) / 100;
                          };
                        }]
                    });
                    modalInstance.result.then(function (newAppeal) {
                        //remove false values
                        angular.forEach(newAppeal.validStatus, function(value, key) {
                          if(!value){ delete newAppeal.validStatus[key]; }
                        });
                        angular.forEach(newAppeal.validTags, function(value, key) {
                          if(!value){ delete newAppeal.validTags[key]; }
                        });

                        api.call('post', 'appeals', {
                          name: newAppeal.name,
                          amount: newAppeal.amount,
                          contact_statuses: _.keys(newAppeal.validStatus),
                          contact_tags: _.keys(newAppeal.validTags),
                          contact_exclude: newAppeal.exclude,
                          account_list_id: (state.current_account_list_id || '')
                        }, function(data) {
                          refreshAppeals(function(){
                            $scope.editAppeal(data.appeal.id);
                          });
                        }, function(){
                          alert(__('An error occurred while creating the appeal.'));
                        });
                    });
                    modalInstance.opened.then(function() {
                        //wait for browser render before resizing
                        setTimeout($.respDialogs);
                    });
                };
            }]
        };
    })
    .directive('rawNumber', function() {
        return {
            require: 'ngModel',
            link: function(_scope, _element, _attrs, ngModel) {
                ngModel.$parsers = [];
                ngModel.$formatters = [];
            }
        };
    });
