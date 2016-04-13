(function(){
    angular
        .module('mpdxApp')
        .component('contact', {
            controller: contactController,
            templateUrl: '/templates/contacts/contact.html',
            bindings: {
                contact: '='
            }
        });

    contactController.$inject = ['$sce', 'contactCache'];

    function contactController($sce, contactCache) {
        var vm = this;
        vm.current_currency_symbol = window.current_currency_symbol;

        vm.getAddress = getAddress;
        vm.getFacebookId = getFacebookId;
        vm.getEmailAddress = getEmailAddress;
        vm.getPerson = getPerson;
        vm.getPrimaryPhone = getPrimaryPhone;
        vm.hasSendNewsletterError = hasSendNewsletterError;

        function getAddress(id){
            var address = _.find(contactCache.getFromCache(vm.contact.id).addresses, { 'id': id });
            if(address.primary_mailing_address){
                return $sce.trustAsHtml(address.street + '<br>' + address.city + ', ' + address.state + ' ' + address.postal_code);
            }else{
                return '';
            }
        }

        function getFacebookId(id){
            return _.find(contactCache.getFromCache(vm.contact.id).facebook_accounts, { 'id': id });
        }

        function getEmailAddress(id){
            return _.find(contactCache.getFromCache(vm.contact.id).email_addresses, { 'id': id });
        }

        function getPerson(id){
            var person = _.find(contactCache.getFromCache(vm.contact.id).people, { 'id': id });
            person.name = person.first_name + ' ' + person.last_name;
            return person;
        }

        function getPrimaryPhone(id){
            var person = _.find(contactCache.getFromCache(vm.contact.id).people, { 'id': id });
            var phone =_.find(contactCache.getFromCache(vm.contact.id).phone_numbers, function (i) {
                return _.contains(person.phone_number_ids, i.id) && i.primary;
            });
            return phone || '';
        }

        function hasSendNewsletterError() {
            data = contactCache.getFromCache(vm.contact.id)
            contact = data.contact
            missing_address = data.addresses.length == 0
            missing_email_address = data.email_addresses.length == 0
            switch(contact.send_newsletter) {
                case 'Both':
                    return missing_address || missing_email_address;
                case 'Physical':
                    return missing_address
                case 'Email':
                    return missing_email_address
            }
            return false;
        }
    }
})();
