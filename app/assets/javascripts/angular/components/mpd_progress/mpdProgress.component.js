(function(){
    angular
        .module('mpdxApp')
        .component('mpdProgress', {
            controller: progressController,
            templateUrl: 'inline/mpd_progress.html' //declared inline at app/views/home/index.html.erb
        });

    progressController.$inject = ['api', '$filter', 'state'];

    function progressController(api, $filter, state) {
        var vm = this;
        vm.start_date = new Date();
        vm.start_date.setHours(0,0,0,0);
        vm.start_date.setDate(vm.start_date.getDate() - vm.start_date.getDay() + 1);
        vm.end_date = new Date(vm.start_date);
        vm.end_date.setDate(vm.start_date.getDate() + 7);
        vm.nextWeek = nextWeek;
        vm.previousWeek = previousWeek;
        vm.errorOccurred = false;

        activate();

        function blankData() {
            vm.data = {
                contacts: {
                    active: '-', referrals_on_hand: '-', referrals: '-'
                },
                phone: {
                    completed: '-', attempted: '-', received: '-',
                    appointments: '-', talktoinperson: '-'
                },
                email: {
                    sent: '-', received: '-'
                },
                facebook: {
                    sent: '-', received: '-'
                },
                text_message: {
                    sent: '-', received: '-'
                },
                electronic: {
                    sent: '-', received: '-', appointments: '-'
                },
                appointments: {
                    completed: '-'
                },
                correspondence: {
                    precall: '-', support_letters: '-', thank_yous: '-', reminders: '-'
                }
            };
        }

        function nextWeek() {
            vm.start_date.setDate(vm.start_date.getDate() + 7);
            vm.end_date.setDate(vm.end_date.getDate() + 7);
            refreshData();
        }

        function previousWeek() {
            vm.start_date.setDate(vm.start_date.getDate() - 7);
            vm.end_date.setDate(vm.end_date.getDate() - 7);
            refreshData();
        }

        function refreshData() {
            blankData();
            var start_date_string = $filter('date')(vm.start_date, 'yyyy-MM-dd');
            var url = 'progress.json?start_date='+start_date_string +
                '&account_list_id=' + state.current_account_list_id

            api.get(url).success(function(newData){
                vm.data = newData;
            }).error(function() {
                vm.errorOccurred = true;
            });
        }

        function activate() {
            refreshData();
        }
    }
})();
