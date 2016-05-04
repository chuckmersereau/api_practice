(function(){
    angular
        .module('mpdxApp')
        .component('appeal', {
            controller: appealController,
            templateUrl: '/templates/appeals/edit.html.erb',
            bindings: {
                id: '@'
            }
        });

    appealController.$inject = ['$filter', 'api', 'state'];

    function appealController($filter, api, state) {
        var vm = this;
        var padStart = _.padStart || _.padLeft;
        vm.mins = _(60).range().map(function(i) { return padStart(i, 2, '0') }).value();

        activate();

        function activate(){
            loadAppeal(vm.id);
        }

        vm.save = function (goBack) {
            api.call('put','appeals/'+ vm.id + '?account_list_id=' + (state.current_account_list_id || ''),
                {"appeal": vm.appeal},
                function() {
                    if(goBack === undefined || goBack)
                        history.back()
                });
        };

        vm.addExcluded = function (contact) {
            vm.addContact(contact.id);
            vm.save(false);
        };

        vm.delete = function (){
            var r = confirm(__('Are you sure you want to delete this appeal?'));
            if(!r){
                return;
            }
            var appeal_url = 'appeals/' + vm.id + '?account_list_id=' + (state.current_account_list_id || '');
            api.call('delete', appeal_url, null, function() {
                history.back()
            });
        };

        vm.contactDetails = function(id){
            var contact = _.find(vm.contacts, { 'id': id });
            if(angular.isDefined(contact)){
                return contact;
            }
            return {};
        };

        vm.contactName = function(id){
            var contact = vm.contactDetails(id);
            return contact.name || '';
        };

        vm.addContact = function(id){
            if(!id){ return; }
            if(_.includes(vm.appeal.contacts, id)){
                alert(__('This contact already exists in this appeal.'));
                return;
            }
            vm.appeal.contacts.push(id);
        };

        vm.deleteContact = function(id){
            _.remove(vm.appeal.contacts, function(c) { return c == id; });
        };

        vm.listDonations = function(contactId){
            var contact = _.find(vm.contacts, { 'id': contactId });
            if(angular.isUndefined(contact) || angular.isUndefined(contact.donor_accounts)){
                return '-';
            }
            var contactDonorIds = _.map(contact.donor_accounts, 'id');
            var donations = _.filter(vm.appeal.donations, function(d) {
                return _.includes(contactDonorIds, d.donor_account_id);
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

        vm.createTask = function(inputContactsObject){
            var task = vm.task;
            var contactsObject = _.keys(_.pick(inputContactsObject, function(val){
                return val;
            }));

            if(!contactsObject.length){
                alert(__('You must check at least one contact.'));
                return;
            }

            vm.creatingBulkTasks = 0;
            var postTask = function(){
                vm.creatingBulkTasks = contactsObject.length;
                if(_.isEmpty(contactsObject)){
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
                }, function(){
                    contactsObject.shift();
                    postTask();
                });
            };

            postTask();
        };

        vm.createTag = function (newTag, inputContactsObject) {
            var contactsObject = _.keys(_.pick(inputContactsObject, function (val) {
                return val;
            }));

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
        };

        vm.exportContactsToCSV = function (selectedContactsMap) {
            var selectedContactIds = _.keys(_.pick(selectedContactsMap, function (selected) {
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

        vm.exportContactsToMailChimpList = function (selectedContactsMap, appealListId) {
            var selectedContactIds = _.keys(_.pick(selectedContactsMap, function (selected) {
                return selected;
            }));

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
        };

        vm.selectAll = function(type){
            if(type === 'all'){
                angular.forEach(vm.appeal.contacts, function (c) {
                    vm.checkedContacts[c] = true;
                });
            }else if(type === 'none'){
                vm.checkedContacts = {};
            }else if(type === 'donated'){
                angular.forEach(vm.appeal.contacts, function (c) {
                    if(_.first(vm.listDonations(c)) === '-'){
                        vm.checkedContacts[c] = false;
                    }else{
                        vm.checkedContacts[c] = true;
                    }
                });
            }else if(type === '!donated'){
                angular.forEach(vm.appeal.contacts, function (c) {
                    if(_.first(vm.listDonations(c)) === '-'){
                        vm.checkedContacts[c] = true;
                    }else{
                        vm.checkedContacts[c] = false;
                    }
                });
            }
        };

        vm.donationAggregates = function() {
            if(!vm.appeal) {
                return { sum: 0, average: 0 };
            }
            var amounts = _.chain(vm.appeal.donations)
                .map(function(d) { return d.appeal_amount || d.amount })
                .reject(function(n) {return !n})
                .value();
            var sum = _.sum(amounts);
            return { sum: sum, average: sum/amounts.length };
        };

        function appealLoaded() {
            vm.checkedContacts = {};
            vm.taskTypes = window.railsConstants.task.ACTIONS;
            vm.task = {
                subject: 'Appeal (' + vm.appeal.name + ')',
                date: moment().format('YYYY-MM-DD'),
                hour: moment().hour(),
                min: moment().minute()
            };
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

            vm.mail_chimp_account_present = $.mpdx.mail_chimp_account_present;

            if ($.mpdx.mail_chimp_lists == null) {
                vm.mail_chimp_lists = [];
            } else {
                vm.mail_chimp_lists = $.mpdx.mail_chimp_lists;
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
