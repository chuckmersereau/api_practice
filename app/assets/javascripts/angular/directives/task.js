angular.module('mpdxApp')
    .directive('task', function () {
        return {
            restrict: 'A',
            templateUrl: '/templates/tasks/task.html',
            scope: {
                task: '=',
                multiselect: '@'
            },
            link: function (scope, element, attrs){
            },
            controller: function ($scope, contactCache, api, railsConstants) {
                //TODO: refactor taskShortListController to use controllerAs so this condition isn't needed or better yet provide the needed data in a binding
                var parentComponentOrController = $scope.$parent.$ctrl || $scope.$parent;

                $scope.visibleComments = false;

                $scope.contacts = {};
                angular.forEach($scope.task.contacts, function(contactId){
                    contactCache.get(contactId, function(contact){
                        $scope.contacts[contactId] = contact.contact.name;
                    });
                });

                //complete options
                if($scope.task.activity_type === 'Call') {
                  $scope.completeResultOptions = railsConstants.task.CALL_RESULTS;
                  $scope.completeActionOptions = railsConstants.task.CALL_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Appointment') {
                  $scope.completeResultOptions = railsConstants.task.APPOINTMENT_RESULTS;
                  $scope.completeActionOptions = railsConstants.task.APPOINTMENT_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Email') {
                  $scope.completeResultOptions = railsConstants.task.EMAIL_RESULTS;
                  $scope.completeActionOptions = railsConstants.task.EMAIL_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Facebook Message') {
                  $scope.completeResultOptions = railsConstants.task.FACEBOOK_MESSAGE_RESULTS;
                  $scope.completeActionOptions = railsConstants.task.FACEBOOK_MESSAGE_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Text Message') {
                  $scope.completeResultOptions = railsConstants.task.TEXT_RESULTS;
                  $scope.completeActionOptions = railsConstants.task.TEXT_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Talk to In Person') {
                    $scope.completeResultOptions = railsConstants.task.TALK_TO_IN_PERSON_RESULTS;
                    $scope.completeActionOptions = railsConstants.task.TALK_TO_IN_PERSON_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Prayer Request') {
                    $scope.completeResultOptions = railsConstants.task.PRAYER_REQUEST_RESULTS;
                    $scope.completeActionOptions = railsConstants.task.PRAYER_REQUEST_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Pre Call Letter') {
                    $scope.completeResultOptions = railsConstants.task.MESSAGE_RESULTS;
                    $scope.completeActionOptions = railsConstants.task.PRE_CALL_LETTER_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Reminder Letter') {
                    $scope.completeResultOptions = railsConstants.task.MESSAGE_RESULTS;
                    $scope.completeActionOptions = railsConstants.task.REMINDER_LETTER_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Support Letter') {
                    $scope.completeResultOptions = railsConstants.task.MESSAGE_RESULTS;
                    $scope.completeActionOptions = railsConstants.task.SUPPORT_LETTER_NEXT_ACTIONS;

                }else if($scope.task.activity_type === 'Letter') {
                    $scope.completeResultOptions = railsConstants.task.MESSAGE_RESULTS;

                }else{
                    $scope.completeResultOptions = railsConstants.task.STANDARD_RESULTS;
                }

                $scope.getComment = function(id){
                    return _.find(parentComponentOrController.comments, { 'id': id });
                };

                $scope.getPerson = function(id){
                    var person = _.find(parentComponentOrController.people, { 'id': id });
                    if(angular.isDefined(person)){
                      person.name = person.first_name + ' ' + person.last_name;
                      return person;
                    }else{
                      return '';
                    }
                };

                $scope.starTask = function(){
                    $scope.task.starred = !$scope.task.starred;
                    api.call('put', 'tasks/'+$scope.task.id, {
                        task: $scope.task
                    });
                };

                $scope.markComplete = function(){
                    //$scope.task.completed = true;
                    api.call('put', 'tasks/'+$scope.task.id, {
                        task: $scope.task
                    }, function(){
                        _.remove(parentComponentOrController.tasks, function(task) { return task.id === $scope.task.id; });
                    });
                };

                $scope.postNewComment = function(){
                    api.call('put', 'tasks/'+$scope.task.id, {
                        task: {
                            activity_comments_attributes: {
                                "0": {
                                    body: $scope.postNewCommentMsg
                                }}
                        }
                    }, function(data){
                        var latestComment = _.maxBy(data.comments, 'id');
                        parentComponentOrController.comments.push(latestComment);
                        $scope.task.comments.push(latestComment.id);
                        $scope.postNewCommentMsg = '';
                    });
                };

                $scope.showContactInfo = function(contactId){
                    if($scope.visibleContactInfo && $scope.contactInfo.contact.id === contactId){
                        $scope.visibleContactInfo = false;
                        return;
                    }else{
                        $scope.visibleContactInfo = true;
                        $scope.visibleComments = false;
                    }


                    contactCache.get(contactId, function(contact){
                        var returnContact = angular.copy(contact);
                        returnContact.phone_numbers = [];
                        returnContact.email_addresses = [];
                        returnContact.facebook_accounts = [];

                        angular.forEach(contact.people, function(i, key){
                            var person = _.find(contact.people, { 'id': i.id });

                            var phone = _.filter(contact.phone_numbers, function(i){
                                return _.includes(person.phone_number_ids, i.id);
                            });
                            if(phone.length > 0){
                                returnContact.people[key].phone_numbers = phone;
                                returnContact.phone_numbers = _.union(returnContact.phone_numbers, phone);
                            }

                            var email = _.filter(contact.email_addresses, function(i){
                                return _.includes(person.email_address_ids, i.id);
                            });
                            if(email.length > 0){
                                returnContact.people[key].email_addresses = email;
                                returnContact.email_addresses = _.union(returnContact.email_addresses, email);
                            }

                            var facebook_account = _.filter(contact.facebook_accounts, function(i){
                                return _.includes(person.facebook_account_ids, i.id);
                            });
                            if(facebook_account.length > 0){
                                returnContact.people[key].facebook_accounts = facebook_account;
                                returnContact.facebook_accounts = _.union(returnContact.facebook_accounts, facebook_account);
                            }
                        });

                        angular.forEach(returnContact.contact.referrals_to_me_ids, function(i, key){
                            contactCache.get(i, function(contact){
                                returnContact.contact.referrals_to_me_ids[key] = {
                                    name: contact.contact.name,
                                    id: i
                                };
                            });
                        });

                        $scope.contactInfo = returnContact;
                    });
                };
            }
        };
    });
