angular.module('mpdxApp')
    .controller('taskFollowupController', ['$scope', '$q', 'api', 'contactCache', function($scope, $q, api, contactCache) {
        $scope.logTask = function(formData) {
            api.call('post', 'tasks/?account_list_id=' + window.current_account_list_id, {
                task: {
                    subject: jQuery('#modal_task_subject').val(),
                    activity_type: jQuery('#modal_task_activity_type').val(),
                    completed: jQuery('#modal_task_completed').val(),
                    completed_at: jQuery('#modal_task_completed_at_1i').val() +
                        '-' + jQuery('#modal_task_completed_at_2i').val() +
                        '-' + jQuery('#modal_task_completed_at_3i').val() +
                        ' ' + jQuery('#modal_task_completed_at_4i').val() +
                        ':' + jQuery('#modal_task_completed_at_5i').val() +
                        ':00',
                    result: jQuery('#modal_task_result').val(),
                    next_action: jQuery('#modal_task_next_action').val(),
                    activity_contacts_attributes:
                        [{
                            contact_id: parseInt(jQuery('#modal_task_activity_contacts_attributes_0_contact_id').val())
                        }]
                    ,
                    tag_list: jQuery('#modal_task_tag_list').val(),
                    activity_comments_attributes: {
                        "0": {
                            body: jQuery('#modal_task_activity_comments_attributes_0_body').val()
                        }
                    }
                }
            }, function (data) {
                $scope.followUpDialog(data.task.id, jQuery('#modal_task_next_action').val());
            });
        };

        $scope.followUpDialog = function(taskId, taskResult){
            if(angular.isDefined($scope.tasks)){
                var mergedTasks = [];
                _($scope.tasks).forEach(function(i) { mergedTasks.push(i); }).value();
                var followUpTask = _.find(_.flatten(mergedTasks), { 'id': parseInt(taskId) });
                followUpDialogCallback(followUpTask, taskResult);
            }else{
                //fetch task data (not on tasks page)
                api.call('get', 'tasks/' + taskId + '?account_list_id=' + window.current_account_list_id, {}, function(tData){
                    followUpDialogCallback(tData.task, taskResult);
                });
            }
        };

        var followUpDialogCallback = function(followUpTask, taskResult){
            var contactsObject = _.map(followUpTask.contacts, function(c) { return {contact_id: c} });

            delete $scope.followUpDialogData;
            $scope.followUpDialogResult = {};

            var dateTwoDaysFromToday = new Date();
            dateTwoDaysFromToday.setDate(dateTwoDaysFromToday.getDate() + 2);
            dateTwoDaysFromToday = dateTwoDaysFromToday.getFullYear() + '-' +
                                   ("0" + (dateTwoDaysFromToday.getMonth() + 1)).slice(-2) + '-' +
                                   ("0" + dateTwoDaysFromToday.getDate()).slice(-2);
            var timeNowHour = ("0" + (new Date().getHours())).slice(-2);
            var timeNowMin = ("0" + (new Date().getMinutes())).slice(-2);

            $scope.followUpSaveFunc = function () {
                if(strContains(taskResult, 'Partner - Financial') &&
                   angular.isUndefined($scope.followUpDialogResult.financialCommitment)){
                    alert('Please enter financial commitment information.');
                    return;
                }

                //Contact Updates
                var newContactStatus;
                if ($scope.followUpDialogResult.updateContactStatus) {
                  if (strContains(taskResult, 'Appointment Scheduled') ||
                      strContains(taskResult, 'Reschedule')) {
                    newContactStatus = 'Appointment Scheduled';
                  } else if (strContains(taskResult, 'Call for Decision')) {
                    newContactStatus = 'Call for Decision';
                  }
                } else if (taskResult == 'Partner - Financial' || taskResult == 'Partner - Special' ||
                   taskResult == 'Partner - Pray' || taskResult == 'Ask in Future' ||
                   taskResult == 'Not Interested') {
                    newContactStatus = taskResult;
                }

                var httpPromises = [];

                if(newContactStatus && followUpTask.contacts.length > 0) {
                    angular.forEach(followUpTask.contacts, function (c) {
                        var contact = {id: c, status: newContactStatus};
                        if($scope.followUpDialogResult.newsletterSignup)
                            contact.send_newsletter = $scope.followUpDialogResult.newsletter.type;
                        if(newContactStatus == 'Partner - Financial') {
                            contact.pledge_amount = $scope.followUpDialogResult.financialCommitment.amount;
                            contact.pledge_frequency = $scope.followUpDialogResult.financialCommitment.frequency;
                            contact.pledge_start_date = $scope.followUpDialogResult.financialCommitment.date;
                        }
                        httpPromises.push(saveContact(contact));
                    });
                    showContactStatus(newContactStatus);
                }

                //Create Call, Message, Email or Text Task
                if ($scope.followUpDialogResult.createCallTask) {
                  httpPromises.push(createTask($scope.followUpDialogResult.callTask, contactsObject,
                               $scope.followUpDialogResult.callTask.type));
                }
                if($scope.followUpDialogResult.createApptTask){
                  httpPromises.push(createTask($scope.followUpDialogResult.apptTask, contactsObject, 'Appointment'));
                }
                if($scope.followUpDialogResult.createThankTask){
                  httpPromises.push(createTask($scope.followUpDialogResult.thankTask, contactsObject, 'Thank'));
                }
                if($scope.followUpDialogResult.createGivingTask){
                  httpPromises.push(createTask($scope.followUpDialogResult.givingTask, contactsObject,
                               $scope.followUpDialogResult.givingTask.type));
                }

                $q.all(httpPromises).then(function(){
                  jQuery('#complete_task_followup_modal').dialog('close');
                });
            };

            if(strContains(taskResult, 'Call') ||
               strContains(taskResult, 'Email') ||
               strContains(taskResult, 'Message') ||
               strContains(taskResult, 'Text') ||
               strContains(taskResult, 'Prayer Request') ||
               strContains(taskResult, 'Talk to In Person')){

                //generic followup task type
                var taskType;
                var taskSubject;

                switch(taskResult) {
                    case 'Call for Decision':
                        taskType = 'Call';
                        taskSubject = 'Call for Decision - ' + followUpTask.subject;
                        break;
                    case 'Call to Follow Up':
                        taskType = 'Call';
                        taskSubject = 'Call to Follow Up - ' + followUpTask.subject;
                        break;
                    case 'Call':
                    case 'Call Again':
                        taskType = 'Call';
                        break;
                    case 'Email':
                    case 'Email Again':
                        taskType = 'Email';
                        break;
                    case 'Message':
                    case 'Message Again':
                        taskType = 'Facebook Message';
                        break;
                    case 'Text':
                    case 'Text Again':
                        taskType = 'Text Message';
                        break;
                    case 'Talk to In Person':
                    case 'Talk to In Person Again':
                        taskType = 'Talk to In Person';
                        break;
                    case 'Prayer Request':
                        taskType = 'Prayer Request';
                        break;
                }

                $scope.followUpDialogData = {
                    message: 'Schedule future task?',
                    callTask: true
                };
                if(strContains(taskResult, 'Call for Decision')) {
                    $scope.followUpDialogData.updateStatus = 'Call for Decision';
                }

                $scope.followUpDialogResult = {
                    createCallTask: true,
                    updateContactStatus: !allFinancialPartners(followUpTask.contacts),
                    callTask: {
                        type: taskType,
                        subject: taskSubject || followUpTask.subject,
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin,
                        tags: followUpTask.tag_list.join()
                    }
                };

            }else if((strContains(taskResult, 'Appointment Scheduled') || strContains(taskResult, 'Reschedule')) &&
                     followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    updateStatus: 'Appointment Scheduled',
                    apptTask: true,
                    callTask: true
                };
                $scope.followUpDialogResult = {
                    createApptTask: true,
                    updateContactStatus: !allFinancialPartners(followUpTask.contacts),
                    apptTask: {
                        subject: 'Support',
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin
                    },
                    callTask: {
                        type: 'Call',
                        subject: followUpTask.subject,
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin,
                        tags: followUpTask.tag_list.join()
                    }
                };

            }else if(strContains(taskResult, 'Partner - Financial') && followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    message: "Contact's status will be updated to 'Partner - Financial'.",
                    thankTask: true,
                    financialCommitment: true,
                    givingTask: true,
                    newsletter: true
                };
                $scope.followUpDialogResult = {
                    thankTask: {
                        subject: 'For Financial Partnership',
                        date: dateTwoDaysFromToday
                    },
                    givingTask: {
                        subject: 'For First Gift',
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin
                    },
                    newsletter: {
                        type: 'Both'
                    }
                };

            }else if(strContains(taskResult, 'Partner - Special') && followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    message: "Contact's status will be updated to 'Partner - Special'.",
                    thankTask: true,
                    givingTask: true,
                    newsletter: true
                };
                $scope.followUpDialogResult = {
                    thankTask: {
                        subject: 'For Special Gift',
                        date: dateTwoDaysFromToday
                    },
                    givingTask: {
                        subject: 'For Gift',
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin
                    },
                    newsletter: {
                        type: 'Both'
                    }
                };

            }else if(strContains(taskResult, 'Partner - Pray') && followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    message: "Contact's status will be updated to 'Partner - Pray'.",
                    newsletter: true
                };
                $scope.followUpDialogResult = {
                    newsletter: {
                        type: 'Both'
                    }
                };

            }else if(strContains(taskResult, 'Ask in Future') && followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    message: "Contact's status will be updated to 'Ask in Future'.",
                    callTask: true,
                    newsletter: true
                };
                $scope.followUpDialogResult = {
                    callTask: {
                        type: 'Call',
                        subject: 'Ask again for financial partnership',
                        date: dateTwoDaysFromToday,
                        hour: timeNowHour,
                        min: timeNowMin,
                        tags: followUpTask.tag_list.join()
                    },
                    newsletter: {
                        type: 'Both'
                    }
                };

            }else if(strContains(taskResult, 'Not Interested') && followUpTask.contacts.length > 0){

                $scope.followUpDialogData = {
                    message: "Contact's status will be updated to 'Not Interested'."
                };

            }

            if(angular.isDefined($scope.followUpDialogData)){
                if(!$scope.$$phase) {
                    $scope.$apply();
                }
                jQuery("#complete_task_followup_modal").dialog({
                    autoOpen: true,
                    modal: true,
                    maxHeight: 600,
                    width: 400
                });
                setTimeout(function() {
                    jQuery("#complete_task_followup_modal").dialog('option', 'position', {my: "center", at: "center", of: window})
                })

                jQuery('.followUpDialogDatepicker').datepicker({
                  autoclose: true,
                  todayHighlight: true,
                  dateFormat: 'yy-mm-dd'
                });

                if($scope.followUpDialogResult.apptTask && window.google) {
                  var autocomplete = new google.maps.places.Autocomplete($('#follow-up-task_location')[0])
                  google.maps.event.addListener(autocomplete, 'place_changed', function() {
                    $('#follow-up-task_location').trigger('change')
                  })
                }
            }
        };

        var createTask = function(task, contactsObject, taskType){
          return api.call('post', 'tasks/?account_list_id=' + window.current_account_list_id, {
              task: {
                  start_at: task.date + ' ' + task.hour + ':' + task.min + ':00',
                  subject: task.subject,
                  tag_list: task.tags,
                  location: task.location,
                  activity_type: taskType,
                  activity_contacts_attributes: contactsObject,
                  activity_comments_attributes: {
                      "0": {
                          body: task.comments
                      }
                  }
              }
          }, function (resp) {
            if(angular.isDefined($scope.refreshVisibleTasks)){
                $scope.refreshVisibleTasks();
            }
            else if($('#tasks-tab')[0])
                angular.element($('#tasks-tab')).scope().syncTask(resp.task);
          });
        };

        var showContactStatus = function(status){
            jQuery('.contact_status').text(__('Status')+': '+__(status));
        };

        var saveContact = function(contact){
          return api.call('put', 'contacts/' + contact.id + '?account_list_id=' + window.current_account_list_id, {
              contact: contact
          });
        };

        var strContains = function(h, n){
            return h.indexOf(n) > -1;
        };

        var allFinancialPartners = function(contactIds) {
          return _.all(contactIds, function (contactId) {
            record = contactCache.getFromCache(contactId);
            return !angular.isUndefined(record) && 
              !angular.isUndefined(record.contact) &&
              record.contact.status == 'Partner - Financial';
          });
        };
    }])
    .directive('taskFollowupDialog', function () {
        return {
            templateUrl: '/templates/tasks/followupDialog.html',
            controller: 'taskFollowupController'
        };
    });
