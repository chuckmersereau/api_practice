angular.module('mpdxApp')
    .directive('taskFollowupDialog', function () {
        return {
            restrict: 'E',
            templateUrl: '/templates/tasks/followupDialog.html',
            controller: function ($scope, api) {
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
                        _($scope.tasks).forEach(function(i) { mergedTasks.push(i); });
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

                    $scope.followUpSaveFunc = function () {
                        if(strContains(taskResult, 'Partner - Financial') &&
                           angular.isUndefined($scope.followUpDialogResult.financialCommitment)){
                            alert('Please enter financial commitment information.');
                            return;
                        }

                        //Contact Updates
                        var newContactStatus;
                        if(strContains(taskResult, 'Appointment Scheduled') || strContains(taskResult, 'Reschedule'))
                            newContactStatus = 'Appointment Scheduled'
                        if(strContains(taskResult, 'Call for Decision') && $scope.followUpDialogResult.updateContactStatus)
                            newContactStatus = 'Call for Decision'
                        if(strContains(taskResult, 'Partner - Financial'))
                            newContactStatus = 'Partner - Financial'
                        if(strContains(taskResult, 'Partner - Special'))
                            newContactStatus = 'Partner - Special'
                        if(strContains(taskResult, 'Partner - Pray'))
                            newContactStatus = 'Partner - Pray'
                        if(strContains(taskResult, 'Ask in Future'))
                            newContactStatus = 'Ask in Future'
                        if(strContains(taskResult, 'Not Interested'))
                            newContactStatus = 'Not Interested'

                        if(newContactStatus && followUpTask.contacts.length > 0) {
                          angular.forEach(followUpTask.contacts, function (c) {
                            var contact = {id: c, status: newContactStatus};
                            if($scope.followUpDialogResult.newsletterSignup)
                                contact.send_newsletter = $scope.followUpDialogResult.newsletter.type;
                            if(newContactStatus == 'Partner - Financial') {
                                contact.pledge_amount = $scope.followUpDialogResult.financialCommitment.amount,
                                pledge_frequency = $scope.followUpDialogResult.financialCommitment.frequency,
                                pledge_start_date = $scope.followUpDialogResult.financialCommitment.date
                            }
                            saveContact(contact);
                          });
                          showContactStatus(newContactStatus);
                        }

                        //Create Call, Message, Email or Text Task
                        if ($scope.followUpDialogResult.createCallTask) {
                            createGenericTask(contactsObject, taskType);
                        }
                        if($scope.followUpDialogResult.createApptTask){
                            createApptTask(contactsObject);
                        }
                        if($scope.followUpDialogResult.createThankTask){
                            createThankTask(contactsObject);
                        }
                        if($scope.followUpDialogResult.createGivingTask){
                            createGivingTask(contactsObject);
                        }

                        jQuery('#complete_task_followup_modal').dialog('close');
                    };

                    if(strContains(taskResult, 'Call') ||
                       strContains(taskResult, 'Call for Decision') ||
                       strContains(taskResult, 'Email') ||
                       strContains(taskResult, 'Message') ||
                       strContains(taskResult, 'Text') ||
                       strContains(taskResult, 'Talk to In Person') ||
                       strContains(taskResult, 'Prayer Request') ||
                       strContains(taskResult, 'Call Again') ||
                       strContains(taskResult, 'Email Again') ||
                       strContains(taskResult, 'Message Again') ||
                       strContains(taskResult, 'Text Again') ||
                       strContains(taskResult, 'Talk to In Person Again')){

                        //generic followup task type
                        var taskType;
                        var taskSubject;

                        if(strContains(taskResult, 'Call for Decision')){
                            taskType = 'Call';
                            taskSubject = 'Call for Decision - ' + followUpTask.subject;
                        }else if(strContains(taskResult, 'Call')){
                            taskType = 'Call';
                        }else if(strContains(taskResult, 'Email')){
                            taskType = 'Email';
                        }else if(strContains(taskResult, 'Message')){
                            taskType = 'Facebook Message';
                        }else if(strContains(taskResult, 'Text')){
                            taskType = 'Text Message';
                        }else if(strContains(taskResult, 'Talk to In Person')){
                            taskType = 'Talk to In Person';
                        }else if(strContains(taskResult, 'Prayer Request')){
                            taskType = 'Prayer Request';
                        }else if(strContains(taskResult, 'Call Again')){
                            taskType = 'Call';
                        }else if(strContains(taskResult, 'Email Again')){
                            taskType = 'Email';
                        }else if(strContains(taskResult, 'Message Again')) {
                            taskType = 'Facebook Message';
                        }else if(strContains(taskResult, 'Text Again')){
                            taskType = 'Text Message';
                        }else if(strContains(taskResult, 'Talk to In Person Again')) {
                            taskType = 'Talk to In Person';
                        }

                        $scope.followUpDialogData = {
                            message: 'Schedule future task?',
                            options: [],
                            callTask: true
                        };
                        if(strContains(taskResult, 'Call for Decision')) {
                          $scope.followUpDialogData.updateStatus = 'Call for Decision';
                        }

                        $scope.followUpDialogResult = {
                            createCallTask: true,
                            updateContactStatus: true,
                            callTask: {
                                type: taskType,
                                subject: taskSubject || followUpTask.subject,
                                date: dateTwoDaysFromToday,
                                hour: ("0" + (new Date().getHours())).slice(-2),
                                min: ("0" + (new Date().getMinutes())).slice(-2),
                                tags: followUpTask.tag_list.join()
                            }
                        };

                    }else if((strContains(taskResult, 'Appointment Scheduled') || strContains(taskResult, 'Reschedule')) && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Appointment Scheduled\'.',
                            options: [],
                            apptTask: true,
                            callTask: true
                        };
                        $scope.followUpDialogResult = {
                            apptTask: {
                                subject: 'Support',
                                date: dateTwoDaysFromToday,
                                hour: ("0" + (new Date().getHours())).slice(-2),
                                min: ("0" + (new Date().getMinutes())).slice(-2)
                            },
                            callTask: {
                              type: 'Call',
                              subject: followUpTask.subject,
                              date: dateTwoDaysFromToday,
                              hour: ("0" + (new Date().getHours())).slice(-2),
                              min: ("0" + (new Date().getMinutes())).slice(-2),
                              tags: followUpTask.tag_list.join()
                            }
                        };

                    }else if(strContains(taskResult, 'Partner - Financial') && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Partner - Financial\'.',
                            options: [],
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
                                hour: ("0" + (new Date().getHours())).slice(-2),
                                min: ("0" + (new Date().getMinutes())).slice(-2)
                            },
                            newsletter: {
                              type: 'Both'
                            }
                        };

                    }else if(strContains(taskResult, 'Partner - Special') && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Partner - Special\'.',
                            options: [],
                            thankTask: true,
                            financialCommitment: false,
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
                                hour: ("0" + (new Date().getHours())).slice(-2),
                                min: ("0" + (new Date().getMinutes())).slice(-2)
                            },
                            newsletter: {
                              type: 'Both'
                            }
                        };

                    }else if(strContains(taskResult, 'Partner - Pray') && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Partner - Pray\'.',
                            options: [],
                            thankTask: false,
                            financialCommitment: false,
                            givingTask: false,
                            newsletter: true
                        };
                        $scope.followUpDialogResult = {
                          newsletter: {
                            type: 'Both'
                          }
                        };

                    }else if(strContains(taskResult, 'Ask in Future') && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Ask in Future\'.',
                            options: [],
                            callTask: true,
                            newsletter: true
                        };
                        $scope.followUpDialogResult = {
                            callTask: {
                                type: 'Ask In Future',
                                subject: 'Ask again for financial partnership',
                                date: dateTwoDaysFromToday,
                                hour: ("0" + (new Date().getHours())).slice(-2),
                                min: ("0" + (new Date().getMinutes())).slice(-2),
                                tags: followUpTask.tag_list.join()
                            },
                            newsletter: {
                              type: 'Both'
                            }
                        };

                    }else if(strContains(taskResult, 'Not Interested') && followUpTask.contacts.length > 0){

                        $scope.followUpDialogData = {
                            message: 'Contact\'s status will be updated to \'Not Interested\'.',
                            options: []
                        };

                    }

                    if(angular.isDefined($scope.followUpDialogData)){
                        $scope.followUpDialogResult.select = $scope.followUpDialogData.options[0];
                        if(!$scope.$$phase) {
                            $scope.$apply();
                        }
                        jQuery("#complete_task_followup_modal").dialog({
                            autoOpen: true,
                            modal: true
                        });

                        jQuery('.followUpDialogDatepicker').datepicker({ dateFormat: 'yy-mm-dd' });
                    }
                };

                var createTask = function(task, contactsObject, taskType){
                    api.call('post', 'tasks/?account_list_id=' + window.current_account_list_id, {
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

                var createThankTask = function(contactsObject){
                    createTask($scope.followUpDialogResult.thankTask, contactsObject, 'Thank');
                };

                var createGivingTask = function(contactsObject){
                    createTask($scope.followUpDialogResult.givingTask, contactsObject, $scope.followUpDialogResult.givingTask.type);
                };

                var createGenericTask = function(contactsObject, taskType){
                    createTask($scope.followUpDialogResult.callTask, contactsObject, taskType);
                };

                var createApptTask = function(contactsObject){
                    createTask($scope.followUpDialogResult.apptTask, contactsObject, 'Appointment');
                };

                var showContactStatus = function(status){
                    status = __(status);
                    jQuery('.contact_status').text(__('Status')+': '+status);
                };

                var saveContact = function(contact){
                    api.call('put', 'contacts/' + contact.id + '?account_list_id=' + window.current_account_list_id, {
                        contact: contact
                    });
                };

                var strContains = function(h, n){
                    return h.indexOf(n) > -1;
                };
            }
        };
    });
