(function(){
    angular
        .module('mpdxApp')
        .component('excludedAppealContacts', {
            controller: excludedAppealContactsController,
            templateUrl: '/templates/appeals/excludedAppealContacts.html.erb',
            bindings: {
                id: '@'
            }
        });

    excludedAppealContactsController.$inject = ['$filter', 'api'];

    function excludedAppealContactsController($filter, api) {
        var vm = this;

        activate();

        function activate(){
            loadAppealExclusions();
        }

        function appealLoaded() {
        }

        function loadAppealExclusions(){
            // api.call('get','appeals/' + vm.id + '/excluded_contacts?account_list_id=' + (window.current_account_list_id || ''), {}, function(data) {
            //     vm.appeal = data.appeal
            // }).then(function() {
            //     appealLoaded();
            // });
        }
    }
})();
