(function(){
    angular
        .module('mpdxApp')
        .component('appeal', {
            controller: appealController,
            templateUrl: '/templates/appeals/edit.html.erb',
            bindings: {
                id: '@',
                firstShow: '@'
            }
        });

    appealController.$inject = ['$filter', 'api', 'state'];

    function appealController($filter, api, state) {
        var vm = this;
        var padStart = _.padStart || _.padLeft;
        vm.mins = _(60).range().map(function(i) { return padStart(i, 2, '0') }).value();
        vm.donationAggregates = {};

        vm.selectedContactIds = selectedContactIds;
        vm.save = save;
        vm.addExcluded = addExcluded;
        vm.delete = deleteAppeal;
        vm.contactDetails = contactDetails;
        vm.contactName = contactName;
        vm.addContact = addContact;
        vm.deleteContact = deleteContact;
        vm.listDonations = listDonations;
        vm.createTask = createTask;
        vm.createTag = createTag;
        vm.exportContactsToCSV = exportContactsToCSV;
        vm.exportContactsToMailChimpList = exportContactsToMailChimpList;
        vm.selectAll = selectAll;

        activate();

        ////////////

        function activate(){
            loadAppeal(vm.id);
        }

        function selectedContactIds(selectedContactsMap) {
            var pickMethod = _.pickBy || _.pick;
            return _.keys(pickMethod(selectedContactsMap, function (selected) {
                return selected;
            }))
        }

        function save(goBack) {
            api.call('put', 'appeals/' + vm.id + '?account_list_id=' + (state.current_account_list_id || ''),
                {"appeal": vm.appeal},
                function () {
                    if (goBack === undefined || goBack)
                        history.back()
                });
        }

        function addExcluded(contact) {
            vm.addContact(contact.id);
            vm.save(false);
        }

        function deleteAppeal() {
            var r = confirm(__('Are you sure you want to delete this appeal?'));
            if(!r){
                return;
            }
            var appeal_url = 'appeals/' + vm.id + '?account_list_id=' + (state.current_account_list_id || '');
            api.call('delete', appeal_url, null, function() {
                history.back()
            });
        }

        function contactDetails(id) {
            var contact = _.find(vm.contacts, {'id': id});
            if (angular.isDefined(contact)) {
                return contact;
            }
            return {};
        }

        function contactName(id) {
            var contact = vm.contactDetails(id);
            return contact.name || '';
        }

        function addContact(id) {
            if (!id) {
                return;
            }
            if (_.includes(vm.appeal.contacts, id)) {
                alert(__('This contact already exists in this appeal.'));
                return;
            }
            vm.appeal.contacts.push(id);
        }

        function deleteContact(id) {
            _.remove(vm.appeal.contacts, function (c) {
                return c == id;
            });
        }

        function listDonations(contactId) {
            var contact = _.find(vm.contacts, {'id': contactId});
            if (angular.isUndefined(contact) || angular.isUndefined(contact.donor_accounts)) {
                return '-';
            }
            var contactDonorIds = _.map(contact.donor_accounts, 'id');
            var donations = _.filter(vm.appeal.donations, function (d) {
                return _.includes(contactDonorIds, d.donor_account_id);
            });

            if (!donations.length) {
                return ['-'];
            } else {
                var str = [];
                angular.forEach(donations, function (d) {
                    var amount = d.appeal_amount ? d.appeal_amount : d.amount;
                    amount = $filter('isoCurrency')(amount, d.currency);
                    var string = d.donation_date + ' - ' + amount;
                    if(state.multi_currencies_for_same_symbol)
                        string += ' ' + d.currency;
                    str.push(string);
                });
                return str;
            }
        }

        function createTask(inputContactsObject) {
            var task = vm.task;
            var contactsObject = selectedContactIds(inputContactsObject);

            if (!contactsObject.length) {
                alert(__('You must check at least one contact.'));
                return;
            }

            vm.creatingBulkTasks = 0;
            var postTask = function () {
                vm.creatingBulkTasks = contactsObject.length;
                if (_.isEmpty(contactsObject)) {
                    alert('Task(s) created.');
                    vm.taskType = '';
                    return;
                }
                var task_start_at = moment(task.date).hour(task.hour).minute(task.min)
                    .format('YYYY-MM-DD HH:mm:ss');
                api.call('post', 'tasks/?account_list_id=' + state.current_account_list_id, {
                    task: {
                        start_at: task_start_at,
                        subject: task.subject,
                        activity_type: task.type,
                        activity_contacts_attributes: [{
                            'contact_id': Number(contactsObject[0])
                        }]
                    }
                }, function () {
                    contactsObject.shift();
                    postTask();
                });
            };

            postTask();
        }

        function createTag(newTag, inputContactsObject) {
            var contactsObject = selectedContactIds(inputContactsObject);

            if (!contactsObject.length) {
                alert(__('You must check at least one contact.'));
                return;
            }

            vm.creatingTag = 0;
            var updateContact = function () {
                vm.creatingTag = contactsObject.length;
                if (_.isEmpty(contactsObject)) {
                    alert('Contact(s) updated.');
                    vm.newTag = '';
                    return;
                }
                var tagList = _.find(vm.contacts, {'id': Number(contactsObject[0])}).tag_list;
                tagList.push(newTag);
                tagList = tagList.join();
                var url = 'contacts/' + contactsObject[0] + '?account_list_id=' +
                    state.current_account_list_id;
                api.call('put', url, {
                    contact: {
                        tag_list: tagList
                    }
                }, function () {
                    contactsObject.shift();
                    updateContact();
                });
            };

            updateContact();
        }

        function exportContactsToCSV(selectedContactsMap) {
            var selectedContactIds = vm.selectedContactIds(selectedContactsMap);

            if (selectedContactIds.length == 0) {
                alert(__('You must check at least one contact.'));
                return;
            }

            window.location.href =
                '/contacts.csv?csv_primary_emails_only=true&' +
                'filters[status]=*&filters[ids]=' + selectedContactIds.join();
        }

        function exportContactsToMailChimpList(selectedContactsMap, appealListId) {
            var selectedContactIds = vm.selectedContactIds(selectedContactsMap);

            if (selectedContactIds.length == 0) {
                alert(__('You must check at least one contact.'));
                return;
            }

            var r = confirm(__('Are you sure you want to export the contacts to this list? ' +
                'If you pick an existing list, this process could have the effect of removing ' +
                'people from it.'));
            if (!r) {
                return;
            }

            api.call('put', 'mail_chimp_accounts/export_appeal_list', {
                    appeal_id: vm.id,
                    appeal_list_id: appealListId,
                    contact_ids: selectedContactIds
                },
                function () {
                    vm.mail_chimp_appeal_load_complete = true;
                });
        }

        function selectAll(type) {
            if (type === 'all') {
                angular.forEach(vm.appeal.contacts, function (c) {
                    vm.checkedContacts[c] = true;
                });
            } else if (type === 'none') {
                vm.checkedContacts = {};
            } else if (type === 'donated') {
                angular.forEach(vm.appeal.contacts, function (c) {
                    if (_.first(vm.listDonations(c)) === '-') {
                        vm.checkedContacts[c] = false;
                    } else {
                        vm.checkedContacts[c] = true;
                    }
                });
            } else if (type === '!donated') {
                angular.forEach(vm.appeal.contacts, function (c) {
                    if (_.first(vm.listDonations(c)) === '-') {
                        vm.checkedContacts[c] = true;
                    } else {
                        vm.checkedContacts[c] = false;
                    }
                });
            }
        }

        function donationAggregates() {
            if(!vm.appeal) {
                return { sum: 0, average: 0 };
            }
            var currencies = {};
            var donations = _.reject(vm.appeal.donations, function(n) { return !n.converted_amount });
            var amounts = _.map(donations, function (donation) {
                var amount = parseFloat(donation.appeal_amount || donation.amount);
                if(currencies[donation.currency] == undefined)
                    currencies[donation.currency] = amount;
                else
                    currencies[donation.currency] += amount;
                return parseFloat(donation.converted_amount);
            });
            var sum = _.sum(amounts);
            return { sum: sum, average: sum/amounts.length, currencies: currencies };
        }

        function appealLoaded() {
            vm.checkedContacts = {};
            vm.taskTypes = window.railsConstants.task.ACTIONS;
            vm.task = {
                subject: 'Appeal (' + vm.appeal.name + ')',
                date: moment().format('YYYY-MM-DD'),
                hour: moment().hour(),
                min: moment().minute()
            };
            vm.donationAggregates = donationAggregates();
            vm.appeal.multiCurrency = vm.appeal.currencies.length > 1 ||
                (vm.appeal.currencies.length == 1 && vm.appeal.currencies[0] != vm.appeal.total_currency);

            var contact_fields = 'Contact.id,Contact.name,Contact.status,Contact.tag_list,'+
                                 'Contact.pledge_frequency,Contact.pledge_amount,'+
                                 'Contact.donor_accounts,Contact.pledge_currency_symbol';
            api.call('get',
                'contacts?filters[status]=*&per_page=5000'+
                '&include='+contact_fields+
                '&account_list_id=' + (state.current_account_list_id || ''),
                {}, function(data) {
                    vm.contacts = data.contacts;
                    vm.newContact = data.contacts[0].id;
                }, null, true);

            vm.mail_chimp_account_present = state.mail_chimp_account_present;

            if (state.mail_chimp_lists == null || JSON.parse(state.mail_chimp_lists) == null) {
                vm.mail_chimp_lists = [];
            } else {
                vm.mail_chimp_lists = JSON.parse(state.mail_chimp_lists);
                if (vm.mail_chimp_lists.length > 0) {
                    vm.selected_mail_chimp_list = vm.mail_chimp_lists[0].id
                }
            }

            vm.mail_chimp_appeal_load_complete = false;

            setTimeout(function() {
                jQuery('.dueDatePicker').datepicker({
                    autoclose: true,
                    todayHighlight: true,
                    dateFormat: 'yy-mm-dd'
                });
            }, 1000);
        }

        function loadAppeal(id){
            var url = 'appeals/' + id + '?account_list_id=' + (state.current_account_list_id || '');
            api.call('get', url, {}, function(data) {
                vm.appeal = data.appeal
            }).then(function() {
                appealLoaded();
            });
        }
    }
})();
