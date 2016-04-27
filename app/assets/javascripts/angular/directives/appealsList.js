angular.module('mpdxApp')
    .directive('appealsList', function () {
        return {
            restrict: 'E',
            templateUrl: '/templates/appeals/list.html',
            controller: function ($scope, $modal, api, state) {
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

                $scope.editAppeal = function(id) {
                    var modalInstance = $modal.open({
                        templateUrl: '/templates/appeals/edit.html',
                        size: 'lg',
                        controller: function($scope, $modalInstance, $filter, appeal){
                            $scope.appeal = angular.copy(appeal);
                            $scope.checkedContacts = {};
                            $scope.taskTypes = window.railsConstants.task.ACTIONS;
                            $scope.task = {
                              subject: 'Appeal (' + $scope.appeal.name + ')',
                              date: moment().format('YYYY-MM-DD'),
                              hour: moment().hour(),
                              min: moment().minute()
                            };
                            api.call('get',
                                     'contacts?filters[status]=*&per_page=5000'+
                                         '&include=Contact.id,Contact.name,Contact.status,Contact.tag_list,Contact.pledge_frequency,Contact.pledge_amount,Contact.donor_accounts,Contact.pledge_currency_symbol'+
                                         '&account_list_id=' + (state.current_account_list_id || ''),
                                     {}, function(data) {
                                $scope.contacts = data.contacts;
                                $scope.newContact = data.contacts[0].id;
                            }, null, true);

                            $scope.mail_chimp_account_present = $.mpdx.mail_chimp_account_present;

                            if ($.mpdx.mail_chimp_lists == null) {
                                $scope.mail_chimp_lists = [];
                            } else {
                                $scope.mail_chimp_lists = $.mpdx.mail_chimp_lists;
                                if ($scope.mail_chimp_lists.length > 0) {
                                    $scope.selected_mail_chimp_list = $scope.mail_chimp_lists[0].id
                                }
                            }

                            $scope.mail_chimp_appeal_load_complete = false;


                            $scope.cancel = function () {
                                $modalInstance.dismiss('cancel');
                            };

                            $scope.save = function () {
                                api.call('put','appeals/'+ $scope.appeal.id + '?account_list_id=' + (state.current_account_list_id || ''),
                                    {"appeal": $scope.appeal},
                                    function(data) {
                                        $modalInstance.close($scope.appeal);
                                    });
                            };

                            $scope.delete = function (){
                                var r = confirm(__('Are you sure you want to delete this appeal?'));
                                if(!r){
                                    return;
                                }
                                api.call('delete', 'appeals/' + id + '?account_list_id=' + (state.current_account_list_id || ''), null, function() {
                                    $modalInstance.dismiss('cancel');
                                    refreshAppeals();
                                });
                            };

                            $scope.contactDetails = function(id){
                                var contact = _.find($scope.contacts, { 'id': id });
                                if(angular.isDefined(contact)){
                                    return contact;
                                }
                                return {};
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
                                    alert(__('This contact already exists in this appeal.'));
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
                                var contactDonorIds = _.pluck(contact.donor_accounts, 'id');
                                var donations = _.filter(appeal.donations, function(d) {
                                  return _.contains(contactDonorIds, d.donor_account_id);
                                });

                                if(!donations.length){
                                    return ['-'];
                                }else{
                                    var str = [];
                                    angular.forEach(donations, function(d){
                                      var amount = d.appeal_amount ? d.appeal_amount : d.amount;
                                      amount = $filter('currency')(amount, contact.pledge_currency_symbol);
                                      str.push(d.donation_date + ' - ' + amount);
                                    });
                                    return str;
                                }
                            };

                            $scope.createTask = function(task, inputContactsObject){
                                var contactsObject = _.keys(_.pick(inputContactsObject, function(val){
                                  return val;
                                }));

                                if(!contactsObject.length){
                                    alert(__('You must check at least one contact.'));
                                    return;
                                }

                                $scope.creatingBulkTasks = 0;
                                var postTask = function(){
                                  $scope.creatingBulkTasks = contactsObject.length;
                                  if(_.isEmpty(contactsObject)){
                                    alert('Task(s) created.');
                                    $scope.taskType = '';
                                    return;
                                  }
                                  api.call('post', 'tasks/?account_list_id=' + state.current_account_list_id, {
                                    task: {
                                      start_at: moment(task.date).hour(task.hour).minute(task.min).format('YYYY-MM-DD HH:mm:ss'),
                                      subject: task.subject,
                                      activity_type: task.type,
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

                          $scope.createTag = function(newTag, inputContactsObject){
                            var contactsObject = _.keys(_.pick(inputContactsObject, function(val){
                              return val;
                            }));

                            if(!contactsObject.length){
                              alert(__('You must check at least one contact.'));
                              return;
                            }

                            $scope.creatingTag = 0;
                            var updateContact = function(){
                              $scope.creatingTag = contactsObject.length;
                              if(_.isEmpty(contactsObject)){
                                alert('Contact(s) updated.');
                                $scope.newTag = '';
                                return;
                              }
                              var tagList = _.find($scope.contacts, { 'id': Number(contactsObject[0]) }).tag_list;
                              tagList.push(newTag);
                              tagList = tagList.join();
                              api.call('put', 'contacts/'+contactsObject[0]+'?account_list_id=' + state.current_account_list_id, {
                                contact: {
                                  tag_list: tagList
                                }
                              }, function(){
                                contactsObject.shift();
                                updateContact();
                              });
                            };

                            updateContact();
                          };

                          $scope.exportContactsToCSV = function(selectedContactsMap) {
                            var selectedContactIds = _.keys(_.pick(selectedContactsMap, function(selected) {
                              return selected;
                            }));

                            if (selectedContactIds.length == 0) {
                              alert(__('You must check at least one contact.'));
                              return;
                            }

                            window.location.href =
                                '/contacts.csv?csv_primary_emails_only=true&' +
                                'filters[status]=*&filters[ids]=' + selectedContactIds.join();
                          };

                          $scope.exportContactsToMailChimpList = function(selectedContactsMap,
                                                                          appealListId ) {
                              var selectedContactIds = _.keys(_.pick(selectedContactsMap, function(selected) {
                                  return selected;
                              }));

                              if (selectedContactIds.length == 0) {
                                  alert (__('You must check at least one contact.'));
                                  return;
                              }

                              var r = confirm(__('Are you sure you want to export the contacts to this list? ' +
                                  'If you pick an existing list, this process could have the effect of removing ' +
                                  'people from it.'));
                              if(!r){
                                    return;
                              }

                              api.call('put','mail_chimp_accounts/export_appeal_list', {
                                      appeal_id: $scope.appeal.id,
                                      appeal_list_id: appealListId,
                                      contact_ids: selectedContactIds
                                  },
                                  function () {
                                      $scope.mail_chimp_appeal_load_complete = true;
                              });
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

                            $scope.donationAggregates = function() {
                                return donationAggregates(appeal.donations);
                            };

                          setTimeout(function() {
                            jQuery('.dueDatePicker').datepicker({
                              autoclose: true,
                              todayHighlight: true,
                              dateFormat: 'yy-mm-dd'
                            });
                          }, 1000);

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
                    modalInstance.opened.then(function() {
                        //wait for browser render before resizing
                        setTimeout($.respDialogs);
                    });
                };

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

                $scope.newAppeal = function(){
                    var modalInstance = $modal.open({
                        templateUrl: '/templates/appeals/wizard.html',
                        size: 'lg',
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
                            api.call('get', 'contacts/tags?account_list_id=' + (state.current_account_list_id || ''), null, function(data) {
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
            }
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
