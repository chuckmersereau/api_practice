describe('contacts', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($injector, $componentController, api, state) {
        self.api = api;
        self.state = state
        $httpBackend = $injector.get('$httpBackend');
        var $rootScope = $injector.get('$rootScope');
        var $scope = $rootScope.$new();

        self.createController = function() {
            return $componentController('contactList', {
                $scope: $scope,
                $http: $httpBackend,
                railsConstants: {
                    contact: {
                        INACTIVE_STATUSES: []
                    }
                }
            });
        };
    }));


    it('reset filter should clear filters', function() {
        var controller = self.createController();

        controller.contactQuery.ids = '1,2';
        controller.contactQuery.tags = ['test'];
        controller.contactQuery.name = 'Steve';
        controller.contactQuery.type = 'person';
        controller.contactQuery.city = ['Green Bay'];
        controller.contactQuery.state = ['WI'];
        controller.contactQuery.newsletter = 'all';
        controller.contactQuery.status = ['test'];
        controller.contactQuery.likely = ['test'];
        controller.contactQuery.church = ['First Church', 'Second Church'];
        controller.contactQuery.referrer = ['-'];

        controller.resetFilters();

        expect(controller.contactQuery.ids).toEqual('');
        expect(controller.contactQuery.tags).toEqual(['']);
        expect(controller.contactQuery.name).toEqual('');
        expect(controller.contactQuery.type).toEqual('');
        expect(controller.contactQuery.city).toEqual(['']);
        expect(controller.contactQuery.state).toEqual(['']);
        expect(controller.contactQuery.newsletter).toEqual('');
        expect(controller.contactQuery.status).toEqual(['active', 'null']);
        expect(controller.contactQuery.likely).toEqual(['']);
        expect(controller.contactQuery.church).toEqual(['']);
        expect(controller.contactQuery.referrer).toEqual(['']);
        expect(controller.contactQuery.relatedTaskAction).toEqual(['']);
    });

    it('url array encode should encode vars', function() {
        var array = ['Testing', '$T$%&^V3'];
        var encoded = self.api.encodeURLarray(array);

        expect(encoded[0]).toEqual('Testing');
        expect(encoded[1]).toEqual('%24T%24%25%26%5EV3');
    });

    it('contact api should return 1 contact', function() {
        var controller = self.createController();

        self.state.current_account_list_id = 1;

        //get user view filters
        $httpBackend.when("GET", "/api/v1/users/me").respond({"user": {"preferences": {"contacts_filter": {"1": {"ids": "", "tags": "", "name": "",
            "type": "", "city": [""], "state": [""], "newsletter": "", "status": [""], "likely": [""], "church": [""], "referrer": [""],
            "timezone": [""], "relatedTaskAction": [""], "appeal": [""], "pledge_frequencies": [""], "pledge_received": "",
            "contact_info_email": "", "contact_info_phone": "", "contact_info_mobile": "", "contact_info_addr": "", "contact_info_facebook": ""},
            "2": {"tags": "", "name": "", "type": "", "city": [""], "state": [""], "region": [""], "newsletter": "all", "status": [""], "likely": [""],
                "church": [""], "referrer": [""], "timezone": [""], "relatedTaskAction": [""], "appeal": [""], "pledge_frequencies": [""],
                "pledge_received": "", "contact_info_email": "", "contact_info_phone": "", "contact_info_mobile": "", "contact_info_addr": "",
                "contact_info_facebook": ""}}, "contacts_view_options": {}, "time_zone": "Atlantic Time (Canada)", "default_account_list": 1},
            "created_at": "2014-04-15T15:49:11.229-03:00", "updated_at": "2014-05-15T12:50:26.113-03:00", "account_list_ids": [1, 2]}}, {});

        //return contact
        $httpBackend.when("GET", /^\/api\/v1\/contacts\?.*/).respond({
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
        $httpBackend.when("PUT", "/api/v1/users/me").respond({}, {});

        $httpBackend.flush();

        expect(controller.totalContacts).toEqual(1);
    });
});
