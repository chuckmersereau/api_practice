describe('contacts', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($injector, $httpBackend, $rootScope, $componentController, api, state, $location) {
        self.api = api;
        self.$httpBackend = $httpBackend;
        self.$location = $location;
        var $scope = $rootScope.$new();

        self.controller = $componentController('contactList', {
            $scope: $scope,
            $http: self.$httpBackend,
            railsConstants: {
                contact: {
                    ACTIVE_STATUSES: ['Never Contacted'],
                    INACTIVE_STATUSES: ['Not Interested']
                }
            }
        });

        self.state = state;
        self.state.current_account_list_id = 2;

        self.defaultFilters = {
            ids: '',
            tags: [''],
            name: '',
            type: '',
            activeAddresses: true,
            city: [''],
            state: [''],
            region: [''],
            metro_area: [''],
            country: [''],
            newsletter: '',
            status: ['active', 'null', 'Never Contacted'],
            likely: [''],
            church: [''],
            referrer: [''],
            timezone: [''],
            currency: [''],
            locale: [''],
            relatedTaskAction: [''],
            appeal: [''],
            pledge_frequencies: [''],
            pledge_received: '',
            contact_info_email: '',
            contact_info_phone: '',
            contact_info_mobile: '',
            contact_info_addr: '',
            contact_info_facebook: '',
            page: 1,
            limit: 25,
            wildcardSearch: null
        };
    }));

    describe('refreshContacts', function(){
        beforeEach(function(){
            self.controller._initializeFilters();
        });

        it('should send a simple http request', function(){
            self.$httpBackend.expectGET('/api/v1/contacts?account_list_id=2').respond(200, {});
            self.$httpBackend.expectPUT('/api/v1/users/me').respond(200, {});

            self.controller._refreshContacts();
            self.$httpBackend.flush();
            expect(self.controller.contactsLoading).toEqual(false);

        });

        it('should send get filtered contacts', function(){
            self.$httpBackend.when("GET", /^\/api\/v1\/contacts\?.*/).respond({
                "people":[
                    {"id":59,"first_name":"Buzz","last_name":"Lightyear","middle_name":"","title":"Mr.","suffix":"","gender":"male","marital_status":"","master_person_id":30,"avatar":"http://res.cloudinary.com/cru/image/upload/c_pad,h_180,w_180/v1399573062/wxlkbf4gs9fumevf3whv.jpg","phone_number_ids":[],"email_address_ids":[29]}
                ],"phone_numbers":[],
                "email_addresses":[
                    {"id":29,"email":"buzz.lightyear@spacerangeracademy.edu","primary":true,"created_at":"2014-04-15T15:59:59.507-03:00","updated_at":"2014-04-15T15:59:59.507-03:00"}
                ],
                "addresses":[
                    {"id":40,"street":"205 10th Ave W","city":"Vancouver","state":"BC","country":"","postal_code":"V5Y 1R9","location":"","start_date":null,"end_date":null,"primary_mailing_address":false}
                ],
                "contacts":[
                    {
                        "id":20,"name":"Lightyear, Buzz","status":"Partner - Special","likely_to_give":"Likely","church_name":"","send_newsletter":"",
                        "avatar":"http://res.cloudinary.com/cru/image/upload/c_pad,h_180,w_180/v1399573062/wxlkbf4gs9fumevf3whv.jpg",
                        "square_avatar":"http://res.cloudinary.com/cru/image/upload/c_fill,g_face,h_50,w_50/v1399573062/wxlkbf4gs9fumevf3whv.jpg",
                        "referrals_to_me_ids":[],"tag_list":[],"uncompleted_tasks_count":1,"person_ids":[59],"address_ids":[40]}
                ],
                "meta":{"total":1,"from":1,"to":1,"page":1,"total_pages":1}
            }, {});

            //save updated view filters
            self.$httpBackend.when("PUT", "/api/v1/users/me").respond(200, {});
            self.controller._refreshContacts();

            self.$httpBackend.flush();

            expect(self.controller.contactsLoading).toEqual(false);
            expect(self.controller.totalContacts).toEqual(1);
            expect(self.controller.page.total).toEqual(1);
            expect(self.controller.page.from).toEqual(1);
            expect(self.controller.page.to).toEqual(1);

            expect(self.controller.contacts).toEqual([{ id: 20, name: 'Lightyear, Buzz', status: 'Partner - Special', likely_to_give: 'Likely', church_name: '', send_newsletter: '', avatar: 'http://res.cloudinary.com/cru/image/upload/c_pad,h_180,w_180/v1399573062/wxlkbf4gs9fumevf3whv.jpg', square_avatar: 'http://res.cloudinary.com/cru/image/upload/c_fill,g_face,h_50,w_50/v1399573062/wxlkbf4gs9fumevf3whv.jpg', referrals_to_me_ids: [  ], tag_list: [  ], uncompleted_tasks_count: 1, person_ids: [ 59 ], address_ids: [ 40 ], pledge_received: false }]);
        });
    });

    describe('buildContactFilterUrl', function(){
        it('should build a simple url if no filters are changed', function(){
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2');
        });
        it('should build an insight filter url', function(){
            self.controller._initializeFilters();
            self.controller.contactQuery.insightFilter = [1, 2];
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2&per_page=25&page=1&filters[ids]=1,2');
        });
        it('should exclude page and per_page from the filters object', function(){
            self.controller.contactQuery.page = 5;
            self.controller.contactQuery.limit = 100;
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2&page=5&per_page=100');
        });
        it('should build a simple url with some filters', function(){
            self.controller.contactQuery.status = ['Never Contacted'];
            self.controller.contactQuery.name = 'testName';
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2&filters[name]=testName&filters[status][]=Never%20Contacted');
        });
        it('should build a complex url with all filters', function(){
            self.controller.contactQuery.ids = '1';
            self.controller.contactQuery.tags = ['tag1'];
            self.controller.contactQuery.name = 'Steve';
            self.controller.contactQuery.type = 'Personal';
            self.controller.contactQuery.activeAddresses = false;
            self.controller.contactQuery.city = ['New York'];
            self.controller.contactQuery.state = ['NY'];
            self.controller.contactQuery.region = ['North'];
            self.controller.contactQuery.metro_area = ['Central'];
            self.controller.contactQuery.country = ['US'];
            self.controller.contactQuery.newsletter = 'Both';
            self.controller.contactQuery.status = ['Never Contacted'];
            self.controller.contactQuery.likely = ['Very'];
            self.controller.contactQuery.church = ['First Church'];
            self.controller.contactQuery.referrer = ['Bob'];
            self.controller.contactQuery.timezone = ['PST'];
            self.controller.contactQuery.currency = ['USD'];
            self.controller.contactQuery.locale = ['en_us'];
            self.controller.contactQuery.relatedTaskAction = ['something'];
            self.controller.contactQuery.appeal = ['December'];
            self.controller.contactQuery.pledge_frequencies = ['Weekly'];
            self.controller.contactQuery.pledge_received = 'Yes';
            self.controller.contactQuery.contact_info_email = 'asdf@asdf.com';
            self.controller.contactQuery.contact_info_phone = '1234567890';
            self.controller.contactQuery.contact_info_mobile = '3216549870';
            self.controller.contactQuery.contact_info_addr = '123 First Street';
            self.controller.contactQuery.contact_info_facebook = 'joe';
            self.controller.contactQuery.page = 2;
            self.controller.contactQuery.limit = 50;
            self.controller.contactQuery.wildcardSearch = 'James';
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2' +
                '&filters[ids]=1' +
                '&filters[tags][]=tag1' +
                '&filters[name]=Steve' +
                '&filters[contact_type]=Personal' +
                '&filters[address_historic]=true' +
                '&filters[city][]=New%20York' +
                '&filters[state][]=NY' +
                '&filters[region][]=North' +
                '&filters[metro_area][]=Central' +
                '&filters[country][]=US' +
                '&filters[newsletter]=Both' +
                '&filters[status][]=Never%20Contacted' +
                '&filters[likely][]=Very' +
                '&filters[church][]=First%20Church' +
                '&filters[referrer][]=Bob' +
                '&filters[timezone][]=PST' +
                '&filters[pledge_currency][]=USD' +
                '&filters[locale][]=en_us' +
                '&filters[relatedTaskAction][]=something' +
                '&filters[appeal][]=December' +
                '&filters[pledge_frequencies][]=Weekly' +
                '&filters[pledge_received]=Yes' +
                '&filters[contact_info_email]=asdf%40asdf.com' +
                '&filters[contact_info_phone]=1234567890' +
                '&filters[contact_info_mobile]=3216549870' +
                '&filters[contact_info_addr]=123%20First%20Street' +
                '&filters[contact_info_facebook]=joe' +
                '&page=2' +
                '&per_page=50' +
                '&filters[wildcard_search]=James');
        });
        it('should build a url with many values for the same filters', function(){
            self.controller.contactQuery.status = ['Never Contacted', 'Unresponsive', 'Not Interested'];
            self.controller.contactQuery.pledge_frequencies = ['Weekly', 'Monthly', 'Quarterly'];
            expect(self.controller._buildContactFilterUrl()).toEqual('contacts?account_list_id=2' +
                '&filters[status][]=Never%20Contacted' +
                '&filters[status][]=Unresponsive' +
                '&filters[status][]=Not%20Interested' +
                '&filters[pledge_frequencies][]=Weekly' +
                '&filters[pledge_frequencies][]=Monthly' +
                '&filters[pledge_frequencies][]=Quarterly');
        });
    });

    describe('handleContactQueryChanges', function(){
        it('should not affect contactQuery.status if active or hidden aren\'t selected', function(){
            var oldStatus = self.controller.contactQuery.status;
            self.controller._handleContactQueryChanges();
            expect(self.controller.contactQuery.status).toEqual(oldStatus);
        });
        it('should add all active statuses if active is chosen', function(){
            self.controller.contactQuery.status = ['active'];
            self.controller._handleContactQueryChanges();
            expect(self.controller.contactQuery.status).toEqual(['active', 'Never Contacted']);
        });
        it('should add all inactive statuses if hidden is chosen', function(){
            self.controller.contactQuery.status = ['hidden'];
            self.controller._handleContactQueryChanges();
            expect(self.controller.contactQuery.status).toEqual(['hidden', 'Not Interested']);
        });
        it('should call clearSelectedContacts and set current page to 1 if the filter changed', function(){
            spyOn(self.controller, 'clearSelectedContacts');
            self.controller.viewPrefsLoaded = true;

            self.controller.contactQuery.status = ['hidden'];
            var oldContactQuery = _.cloneDeep(self.controller.contactQuery);
            self.controller.contactQuery.status = ['active'];
            self.controller._handleContactQueryChanges(oldContactQuery);
            expect(self.controller.clearSelectedContacts).toHaveBeenCalled();
            expect(self.controller.page.current).toEqual(1);
        });
    });

    describe('loadViewPreferences', function(){
        beforeEach(function(){
            self.controller._initializeFilters();
        });

        it('should load view preferences into contactQuery, using defaults for missing keys', function(){
            self.controller._loadViewPreferences();
            self.$httpBackend.expectGET('/api/v1/users/me').respond(200, {
                user: {
                    preferences: {
                        contacts_filter: {
                            2: {
                                name: 'Test'
                            }
                        }
                    }
                }
            });

            var output = _.clone(self.defaultFilters);
            output.name = 'Test';
            output.status = [ 'active', 'null', 'Never Contacted' ];
            self.$httpBackend.flush();
            expect(self.controller.contactQuery).toEqual(output);
        });
        it('should not mutate contactQuery if response current_account_list_id isn\'t found', function(){
            self.$httpBackend.expectGET('/api/v1/users/me').respond(200, {
                user: {
                    preferences: {
                        contacts_filter: {
                            3: {
                                name: 'Test'
                            }
                        }
                    }
                }
            });

            self.controller._loadViewPreferences();
            self.$httpBackend.flush();
            expect(self.controller.contactQuery).toEqual(self.defaultFilters);
        });
    });

    describe('getChangedFilterPanelGroups', function(){
        beforeEach(function(){
            self.controller._initializeFilters();
        });

        it('should return the names of filters that are not in a group', function(){
            self.controller.contactQuery.type = 'chosenType';
            self.controller.contactQuery.newsletter = 'chosenNewsletter';
            expect(self.controller._getChangedFilterPanelGroups()).toEqual(['type', 'newsletter']);
        });
        it('should return the names of filter groups where a filter changed', function(){
            self.controller.contactQuery.pledge_frequencies = 'chosenPledgeFrequency';
            self.controller.contactQuery.contact_info_email = 'chosenContactInfoEmail';
            expect(self.controller._getChangedFilterPanelGroups()).toEqual(['commitment_details', 'contact_info']);
        });
        it('should return the names of both filters without a group and changed filter groups', function(){
            self.controller.contactQuery.state = 'chosenState';
            self.controller.contactQuery.status = 'active';
            expect(self.controller._getChangedFilterPanelGroups()).toEqual(['status', 'contact_location']);
        });
    });

    describe('diffContactFilters', function() {
        it('should output an empty array if there are no differences', function () {
            var left = {
                a: 1,
                b: 2
            };
            expect(self.controller._diffContactFilters(left, left)).toEqual([]);
        });
        it('should output the key of a single difference', function () {
            var left = {
                a: 1,
                b: 2
            };
            var right = {
                a: 1,
                b: 4
            };
            expect(self.controller._diffContactFilters(left, right)).toEqual(['b']);
        });
        it('should output the keys of a multiple differences', function () {
            var left = {
                a: 1,
                b: 2
            };
            var right = {
                a: 3,
                b: 4
            };
            expect(self.controller._diffContactFilters(left, right)).toEqual(['a', 'b']);
        });
        it('should handle missing keys on the right', function() {
            var left = {
                a: 1,
                b: 2
            };
            var right = {
                a: 1
            };
            expect(self.controller._diffContactFilters(left, right)).toEqual(['b']);
        });
        it('should handle missing keys on the left', function() {
            var left = {
                a: 1
            };
            var right = {
                a: 1,
                b: 2
            };
            expect(self.controller._diffContactFilters(left, right)).toEqual(['b']);
        });
        it('should ignore keys in the ignore array', function() {
            var left = {
                a: 1,
                b: 3
            };
            var right = {
                a: 2,
                b: 4
            };
            expect(self.controller._diffContactFilters(left, right, ['a'])).toEqual(['b']);
        });
    });

    describe('isEmptyFilter', function() {
        beforeEach(function(){
            self.controller._initializeFilters();
        });

        it('should return true if filters have not been modified', function () {
            expect(self.controller.isEmptyFilter()).toEqual(true);
        });
        it('should return false if filters have been modified', function () {
            self.controller.contactQuery.status = ['Never Contacted'];
            expect(self.controller.isEmptyFilter()).toEqual(false);
        });
        it('should return true if only limit or page have been modified', function () {
            self.controller.contactQuery.limit = 100;
            self.controller.contactQuery.page = 5;
            expect(self.controller.isEmptyFilter()).toEqual(true);
        });
    });

    describe('initializeFilters', function() {
        it('should initialize filters with limit from state and wildcardSearch from url param', function () {
            self.state.contact_limit = 100;
            self.$location.search('q', 'searchQuery');
            self.controller._initializeFilters();
            expect(_.omit(self.controller.contactQuery, ['limit', 'wildcardSearch'])).toEqual(_.omit(self.defaultFilters, ['limit', 'wildcardSearch']));
            expect(self.controller.contactQuery.limit).toEqual(100);
            expect(self.controller.contactQuery.wildcardSearch).toEqual('searchQuery');
        });
        it('should call clearSelectedContacts if performing a wildcardSearch', function(){
            spyOn(self.controller, 'clearSelectedContacts');
            self.$location.search('q', 'searchQuery');

            self.controller._initializeFilters();
            expect(self.controller.clearSelectedContacts).toHaveBeenCalled();
        });

        afterEach(function(){
            self.state.contact_limit = null;
            self.$location.search('q', null);
        });
    });

    describe('resetFilters', function(){
        beforeEach(function(){
            self.controller._initializeFilters();
        });

        it('should clear filters', function() {
            self.controller.contactQuery.ids = '1,2';
            self.controller.contactQuery.tags = ['test'];
            self.controller.contactQuery.name = 'Steve';
            self.controller.contactQuery.type = 'person';
            self.controller.contactQuery.city = ['Green Bay'];
            self.controller.contactQuery.state = ['WI'];
            self.controller.contactQuery.newsletter = 'all';
            self.controller.contactQuery.status = ['test'];
            self.controller.contactQuery.likely = ['test'];
            self.controller.contactQuery.church = ['First Church', 'Second Church'];
            self.controller.contactQuery.referrer = ['-'];

            self.controller.resetFilters();

            expect(self.controller.contactQuery).toEqual(self.defaultFilters);
        });
    });

    describe('activate', function(){
        it('contact api should return 1 contact', function() {
            self.controller.$onInit();

            self.state.current_account_list_id = 1;

            //get user view filters
            self.$httpBackend.when("GET", "/api/v1/users/me").respond({"user": {"preferences": {"contacts_filter": {"1": {"ids": "", "tags": "", "name": "",
                "type": "", "city": [""], "state": [""], "newsletter": "", "status": [""], "likely": [""], "church": [""], "referrer": [""],
                "timezone": [""], "relatedTaskAction": [""], "appeal": [""], "pledge_frequencies": [""], "pledge_received": "",
                "contact_info_email": "", "contact_info_phone": "", "contact_info_mobile": "", "contact_info_addr": "", "contact_info_facebook": ""},
                "2": {"tags": "", "name": "", "type": "", "city": [""], "state": [""], "region": [""], "newsletter": "all", "status": [""], "likely": [""],
                    "church": [""], "referrer": [""], "timezone": [""], "relatedTaskAction": [""], "appeal": [""], "pledge_frequencies": [""],
                    "pledge_received": "", "contact_info_email": "", "contact_info_phone": "", "contact_info_mobile": "", "contact_info_addr": "",
                    "contact_info_facebook": ""}}, "contacts_view_options": {}, "time_zone": "Atlantic Time (Canada)", "default_account_list": 1},
                "created_at": "2014-04-15T15:49:11.229-03:00", "updated_at": "2014-05-15T12:50:26.113-03:00", "account_list_ids": [1, 2]}}, {});

            //return contact
            self.$httpBackend.when("GET", /^\/api\/v1\/contacts\?.*/).respond({
                "people":[
                    {"id":59,"first_name":"Buzz","last_name":"Lightyear","middle_name":"","title":"Mr.","suffix":"","gender":"male","marital_status":"","master_person_id":30,"avatar":"http://res.cloudinary.com/cru/image/upload/c_pad,h_180,w_180/v1399573062/wxlkbf4gs9fumevf3whv.jpg","phone_number_ids":[],"email_address_ids":[29]}
                ],"phone_numbers":[],"email_addresses":[
                    {"id":29,"email":"buzz.lightyear@spacerangeracademy.edu","primary":true,"created_at":"2014-04-15T15:59:59.507-03:00","updated_at":"2014-04-15T15:59:59.507-03:00"}
                ],"addresses":[
                    {"id":40,"street":"205 10th Ave W","city":"Vancouver","state":"BC","country":"","postal_code":"V5Y 1R9","location":"","start_date":null,"end_date":null,"primary_mailing_address":false}
                ],"contacts":[
                    {
                        "id":20,"name":"Lightyear, Buzz","status":"Partner - Special","likely_to_give":"Likely","church_name":"","send_newsletter":"",
                        "avatar":"http://res.cloudinary.com/cru/image/upload/c_pad,h_180,w_180/v1399573062/wxlkbf4gs9fumevf3whv.jpg",
                        "square_avatar":"http://res.cloudinary.com/cru/image/upload/c_fill,g_face,h_50,w_50/v1399573062/wxlkbf4gs9fumevf3whv.jpg",
                        "referrals_to_me_ids":[],"tag_list":[],"uncompleted_tasks_count":1,"person_ids":[59],"address_ids":[40]}
                ]
                ,"meta":{"total":1,"from":1,"to":1,"page":1,"total_pages":1}
            }, {});

            //save updated view filters
            self.$httpBackend.when("PUT", "/api/v1/users/me").respond(200, {});

            self.$httpBackend.flush();

            expect(self.controller.totalContacts).toEqual(1);
        });
    });

    describe('tags', function(){
        it('tag should be active', function() {
            self.controller._initializeFilters();

            self.controller.filterTagsSelect = [''];
            self.controller.tagClick('university');

            expect(self.controller.tagIsActive('university')).toBe(true);
        });
    });
});
