angular.module('mpdxApp')
    .directive('appealsList', function () {
        return {
            restrict: 'E',
            templateUrl: '/templates/appeals/list.html',
            controller: function ($scope, $modal, api) {
                var refreshAppeals = function(callback){
                    api.call('get','appeals?account_list_id=' + (window.current_account_list_id || ''), {}, function(data) {
                        $scope.appeals = data.appeals;
                      if(_.isFunction(callback)){
                        callback(data);
                      }
                    });
                };
                refreshAppeals();

                $scope.editAppeal = function(id) {
                    var modalInstance = $modal.open({
                        templateUrl: '/templates/appeals/edit.html',
                        controller: function($scope, $modalInstance, appeal){
                            $scope.appeal = angular.copy(appeal);
                            $scope.checkedContacts = {};
                            $scope.taskTypes = window.railsConstants.task.ACTIONS;

                            api.call('get','contacts?filters[status]=*&per_page=5000&include=Contact.id,Contact.name,Contact.donor_accounts&account_list_id=' + (window.current_account_list_id || ''), {}, function(data) {
                                $scope.contacts = data.contacts;
                                $scope.newContact = data.contacts[0].id;
                            }, null, true);

                            $scope.cancel = function () {
                                $modalInstance.dismiss('cancel');
                            };

                            $scope.save = function () {
                                api.call('put','appeals/'+ $scope.appeal.id + '?account_list_id=' + (window.current_account_list_id || ''),
                                    {"appeal": $scope.appeal},
                                    function(data) {
                                        $modalInstance.close($scope.appeal);
                                    });
                            };

                            $scope.contactName = function(id){
                                var contact = _.find($scope.contacts, { 'id': id });
                                if(angular.isDefined(contact)){
                                    return contact.name;
                                }
                                return '';
                            };

                            $scope.addContact = function(id){
                                if(!id){ return; }
                                if(_.contains($scope.appeal.contacts, id)){
                                    alert('This contact already exists in this appeal.');
                                    return;
                                }
                                $scope.appeal.contacts.push(id);
                            };

                            $scope.deleteContact = function(id){
                                _.remove($scope.appeal.contacts, function(c) { return c == id; });
                            };

                            $scope.listDonations = function(contactId){
                                var contact = _.find($scope.contacts, { 'id': contactId });
                                if(angular.isUndefined(contact) || angular.isUndefined(contact.donor_accounts)){
                                    return '-';
                                }
                                var contactDonorIds = _.flatten(contact.donor_accounts, 'id');
                                var donations = _.where(appeal.donations, function(d) {
                                    return _.contains(contactDonorIds, d.donor_account_id);
                                });

                                if(!donations.length){
                                    return ['-'];
                                }else{
                                    var str = [];
                                    angular.forEach(donations, function(d){
                                      if(_.isNull(d.appeal_amount) || _.isEmpty(d.appeal_amount)){
                                        str.push(d.donation_date + ' - $' + $scope.formatNumber(d.amount));
                                      }else{
                                        str.push(d.donation_date + ' - $' + $scope.formatNumber(d.appeal_amount));
                                      }
                                    });
                                    return str;
                                }
                            };

                            $scope.createTask = function(taskType, inputContactsObject){
                                var contactsObject = _.keys(_.pick(inputContactsObject, function(val){
                                  return val;
                                }));

                                if(!contactsObject.length){
                                    alert('You must check at least one contact.');
                                    return;
                                }

                                $scope.creatingBulkTasks = true;
                                var postTask = function(){
                                  if(_.isEmpty(contactsObject)){
                                    alert('Task(s) created.');
                                    $scope.taskType = '';
                                    $scope.creatingBulkTasks = false;
                                    return;
                                  }
                                  api.call('post', 'tasks/?account_list_id=' + window.current_account_list_id, {
                                    task: {
                                      start_at: moment().add(7, 'days').format('YYYY-MM-DD HH:mm:ss'),
                                      subject: 'Appeal (' + $scope.appeal.name + ')',
                                      activity_type: taskType,
                                      activity_contacts_attributes: [{
                                        'contact_id': Number(contactsObject[0])
                                      }]
                                    }
                                  }, function(){
                                    contactsObject.shift();
                                    postTask();
                                  });
                                };

                                postTask();
                            };

                            $scope.selectAll = function(type){
                                if(type === 'all'){
                                    angular.forEach($scope.appeal.contacts, function (c) {
                                        $scope.checkedContacts[c] = true;
                                    });
                                }else if(type === 'none'){
                                    $scope.checkedContacts = {};
                                }else if(type === 'donated'){
                                    angular.forEach($scope.appeal.contacts, function (c) {
                                        if(_.first($scope.listDonations(c)) === '-'){
                                            $scope.checkedContacts[c] = false;
                                        }else{
                                            $scope.checkedContacts[c] = true;
                                        }
                                    });
                                }else if(type === '!donated'){
                                    angular.forEach($scope.appeal.contacts, function (c) {
                                        if(_.first($scope.listDonations(c)) === '-'){
                                            $scope.checkedContacts[c] = true;
                                        }else{
                                            $scope.checkedContacts[c] = false;
                                        }
                                    });
                                }
                            };
                        },
                        resolve: {
                            appeal: function () {
                                return _.find($scope.appeals, { 'id': id });
                            }
                        }
                    });

                    modalInstance.result.then(function (updatedAppeal) {
                        var index = _.findIndex($scope.appeals, { 'id': updatedAppeal.id });
                        $scope.appeals[index] = updatedAppeal;
                    });
                };

                $scope.deleteAppeal = function(id){
                    var r = confirm('Are you sure you want to delete this appeal?');
                    if(!r){
                        return;
                    }
                    api.call('delete', 'appeals/' + id + '?account_list_id=' + (window.current_account_list_id || ''), null, function() {
                        refreshAppeals();
                    });
                };

                $scope.donationTotal = function(donations){
                  var sum = 0;
                  angular.forEach(donations, function(d){
                    if(_.isNull(d.appeal_amount) || _.isEmpty(d.appeal_amount)){
                      sum += Number(d.amount);
                    }else{
                      sum += Number(d.appeal_amount);
                    }
                  });
                  return sum;
                };

                $scope.percentComplete = function(donationsTotal, goal){
                  goal = Number(goal);
                  if(goal === 0){
                    return 0;
                  }
                  return parseInt((donationsTotal / goal) * 100);
                };

                $scope.newAppeal = function(){
                    var modalInstance = $modal.open({
                        templateUrl: '/templates/appeals/wizard.html',
                        controller: function($scope, $modalInstance){
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
                            api.call('get', 'contacts/tags?account_list_id=' + (window.current_account_list_id || ''), null, function(data) {
                              $scope.contactTags = data.tags.sort();
                            }, null, true);

                            $scope.cancel = function () {
                                $modalInstance.dismiss('cancel');
                            };

                            $scope.save = function () {
                                $modalInstance.close($scope.appeal);
                            };

                          $scope.calculateGoal = function(goal){
                            var adminPercent = Number(goal.adminPercent) / 100 + 1;
                            $scope.appeal.amount = Math.round((Number(goal.initial) + Number(goal.letterCost)) * adminPercent * 100) / 100;
                          };
                        }
                    }).result.then(function (newAppeal) {
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
                          account_list_id: (window.current_account_list_id || '')
                        }, function(data) {
                          refreshAppeals(function(){
                            $scope.editAppeal(data.appeal.id);
                          });
                        }, function(){
                          alert('An error occurred while creating the appeal.');
                        });
                    });
                };

                $scope.formatNumber = function(number){
                  return Number(number).toFixed(2).replace(/\d(?=(\d{3})+\.)/g, '$&,');
                };
            }
        };
    });