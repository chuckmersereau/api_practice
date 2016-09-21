describe('contactListItem', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($injector, $rootScope, $componentController, contactCache) {
        var $scope = $rootScope.$new();
        self.contactCache = contactCache;

        self.controller = $componentController('contactListItem', {
            $scope: $scope,
            contactCache: self.contactCache
        });
    }));

    describe('getAddresses', function(){
        var addresses = [
            {
                "id": 86,
                "street": "40 King St W",
                "city": "Toronto",
                "state": "ON",
                "country": "Canada",
                "postal_code": "M5H 1H1",
                "location": "Home",
                "start_date": "2016-07-05",
                "end_date": null,
                "primary_mailing_address": true,
                "historic": false,
                "geo": null
            },
            {
                id: 100
            },
            {
                "id": 257,
                "street": "New Street",
                "city": "New City",
                "state": "NS",
                "country": null,
                "postal_code": "12345",
                "location": "Business",
                "start_date": "2016-06-28",
                "end_date": null,
                "primary_mailing_address": false,
                "historic": true,
                "geo": null
            }
        ];
        beforeEach(function(){
            self.controller.contact = {
                id: 5,
                address_ids: [86, 257]
            };
            self.contactCache.update(self.controller.contact.id, {
                addresses: addresses
            });
        });
        it('should lookup and get all address that correspond to a contact', function(){
            expect(self.controller.getAddresses()).toEqual([ addresses[0], addresses[2] ]);
        });
    });
});
