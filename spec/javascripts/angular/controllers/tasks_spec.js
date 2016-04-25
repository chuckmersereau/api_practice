describe('tasks', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($componentController, $rootScope) {
        var $scope = $rootScope.$new();

        self.createController = function() {
            return $componentController('contactList', {
                '$scope': $scope
            });
        };
    }));

    var task = [
        {
            account_list_id: 1,
            activity_type: "Appointment",
            comments: [],
            comments_count: 0,
            completed: false,
            completed_at: null,
            contacts: [18, 20],
            created_at: "2014-04-28T09:17:15.816-04:00",
            due_date: "2014-04-29T09:17:00.000-04:00",
            id: 1,
            person_ids: [],
            starred: false,
            subject: "Appointment with Ryan",
            tag_list: ['university'],
            updated_at: "2014-04-28T09:17:15.816-04:00"
        },
        {
            account_list_id: 1,
            activity_type: "Call",
            comments: [],
            comments_count: 0,
            completed: false,
            completed_at: null,
            contacts: [16, 12],
            created_at: "2014-04-28T09:17:15.816-04:00",
            due_date: "2014-04-29T09:17:00.000-04:00",
            id: 2,
            person_ids: [],
            starred: false,
            subject: "Call with Ryan",
            tag_list: ['church'],
            updated_at: "2014-04-28T09:17:15.816-04:00"
        }
    ];

    it('tag should be active', function() {
        var controller = self.createController();

        controller.filterTagsSelect = [''];
        controller.tagClick('university');

        expect(controller.tagIsActive('university')).toBe(true);
    });
});
