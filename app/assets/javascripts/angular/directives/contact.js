angular.module('mpdxApp')
    .directive('contact', function () {
        return {
            restrict: 'A',
            templateUrl: '/templates/contacts/contact.html',
            scope: {
                contact: '='
            },
            link: function (scope, element, attrs){
            },
            controller: function ($scope, $sce, contactCache) {
                $scope.current_currency_symbol = window.current_currency_symbol;

                $scope.getAddress = function(id){
                    var address = _.find(contactCache.getFromCache($scope.contact.id).addresses, { 'id': id });
                    if(address.primary_mailing_address){
                        return $sce.trustAsHtml(address.street + '<br>' + address.city + ', ' + address.state + ' ' + address.postal_code);
                    }else{
                        return '';
                    }
                };

                $scope.getFacebookId = function(id){
                  return _.find(contactCache.getFromCache($scope.contact.id).facebook_accounts, { 'id': id });
                };

                $scope.getEmailAddress = function(id){
                  return _.find(contactCache.getFromCache($scope.contact.id).email_addresses, { 'id': id });
                };

                $scope.getPerson = function(id){
                    var person = _.find(contactCache.getFromCache($scope.contact.id).people, { 'id': id });
                    person.name = person.first_name + ' ' + person.last_name;
                    return person;
                };

                $scope.getPrimaryPhone = function(id){
                    var person = _.find(contactCache.getFromCache($scope.contact.id).people, { 'id': id });
                    var phone =_.find(contactCache.getFromCache($scope.contact.id).phone_numbers, function (i) {
                        return _.contains(person.phone_number_ids, i.id) && i.primary;
                    });
                    return phone || '';
                };

                $scope.hasSendNewsletterError = function() {
                    data = contactCache.getFromCache($scope.contact.id)
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
                };
            }
        };
    });
