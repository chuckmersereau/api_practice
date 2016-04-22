(function(){
    angular
        .module('mpdxApp')
        .component('appeal', {
            controller: appealController,
            templateUrl: '/templates/appeals/edit.html.erb', //Idk if this is the template you wanted
            bindings: {
                id: '@'
            }
        });

    appealController.$inject = ['$filter', 'api'];

    function appealController($filter, api) {
        var vm = this;

        activate();

        function activate(){
            loadAppeal(vm.id);
        }

        vm.save = function () {
            api.call('put','appeals/'+ vm.appeal.id + '?account_list_id=' + (window.current_account_list_id || ''),
                {"appeal": vm.appeal},
                function(data) {
                    $modalInstance.close(vm.appeal);
                });
        };

        vm.delete = function (){
            var r = confirm(__('Are you sure you want to delete this appeal?'));
            if(!r){
                return;
            }
            api.call('delete', 'appeals/' + id + '?account_list_id=' + (window.current_account_list_id || ''), null, function() {
                $modalInstance.dismiss('cancel');
                refreshAppeals();
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
            var contact = _.find(vm.contacts, { 'id': id });
            if(angular.isDefined(contact)){
                return contact.name;
            }
            return '';
        };

        vm.addContact = function(id){
            if(!id){ return; }
            if(_.contains(vm.appeal.contacts, id)){
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
            var contactDonorIds = _.pluck(contact.donor_accounts, 'id');
            var donations = _.filter(vm.appeal.donations, function(d) {
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

        function appealLoaded() {
            vm.checkedContacts = {};
            vm.taskTypes = window.railsConstants.task.ACTIONS;
            vm.task = {
                subject: 'Appeal (' + vm.appeal.name + ')',
                date: moment().format('YYYY-MM-DD'),
                hour: moment().hour(),
                min: moment().minute()
            };
            api.call('get',
                'contacts?filters[status]=*&per_page=5000'+
                '&include=Contact.id,Contact.name,Contact.status,Contact.tag_list,Contact.pledge_frequency,Contact.pledge_amount,Contact.donor_accounts,Contact.pledge_currency_symbol'+
                '&account_list_id=' + (window.current_account_list_id || ''),
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
            api.call('get','appeals/' + id + '?account_list_id=' + (window.current_account_list_id || ''), {}, function(data) {
                vm.appeal = data.appeal
            }).then(function() {
                appealLoaded();
            });
        }
    }
})();


//Call this anywhere in html using:
//<appeal id="<%= appeal_id %>"></appeal>

//In your template, because components use the controllerAs syntax, you can access vm.id with $ctrl.id
//With controllerAs, vm.id === $scope.$ctrl.id
//You could name $ctrl somethine else like appeal if you wanted https://toddmotto.com/exploring-the-angular-1-5-component-method/
