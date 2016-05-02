(function(){
    angular
        .module('mpdxApp')
        .component('excludedAppealContacts', {
            controller: excludedAppealContactsController,
            templateUrl: '/templates/appeals/excludedAppealContacts.html.erb',
            bindings: {
                appealId: '@'
            }
        });

    excludedAppealContactsController.$inject = ['$scope', 'api', 'state'];

    function excludedAppealContactsController($scope, api, state) {
        var vm = this;
        vm.loading = true;
        vm.error = false;
        vm.showByDefault = false;
        vm.exclusions = [];

        activate();

        function activate(){
            loadAppealExclusions();
            vm.lastSixMonths = ["Nov '15", "Dec '15","Jan '16","Feb '16","Mar '16","Apr '16"]
        }

        vm.add = function (exclusion) {
            if(exclusion.ajax)
                return;
            exclusion.ajax = true;
            var url = 'appeals/' + vm.appealId + '/exclusions/' + exclusion.id + '?account_list_id=' + (state.current_account_list_id || '');
            api.call('delete', url, {}).then(function() {
                _.remove(vm.exclusions, function (e) {
                    return e == exclusion
                });
                $scope.$parent.$ctrl.addExcluded(exclusion.contact);
            }, function (error) {
                exclusion.ajax = false;
                alert('Exclusion failed to be added to the appeal: ' + error.statusText);
            });
        };

        function appealLoaded() {
            angular.forEach(vm.exclusions, function(exclusion) {
                exclusion.lastSixMonths = groupDonations(exclusion.donations);
            })
        }

        function loadAppealExclusions(){
            api.call('get','appeals/' + vm.appealId + '/exclusions?account_list_id=' + (state.current_account_list_id || ''), {}, function(data) {
                vm.exclusions = data.appeal_exclusions;
                vm.loading = false;
            }).then(function() {
                appealLoaded();
                vm.showByDefault = vm.exclusions.length > 0;
            }, function () {
                vm.error = true;
            });
        }

        function groupDonations(donations) {
            console.log(donations);
            var i = 0;
            var d = new Date();
            var begining = new Date(d.getFullYear(), d.getMonth() - 5, 1);
            var nextMonth = new Date(begining.getFullYear(), begining.getMonth() + 1, 1);

            var result = [];
            while(i < 6) {
                var monthObject = { month: new Date(begining.getTime()), donations: [] };
                angular.forEach(donations, function (donation) {
                    console.log(ymdDate(begining));
                    if(donation.donation_date < ymdDate(nextMonth) && donation.donation_date >= ymdDate(begining))
                        monthObject.donations.push(donation)
                });
                result.push(monthObject);
                begining.setMonth(begining.getMonth() + 1);
                nextMonth.setMonth(nextMonth.getMonth() + 1);
                i++;
            }
            return result;
        }

        function ymdDate(date) {
            if(date.getMonth() < 10)
                return date.getFullYear() + '-0' + (date.getMonth() + 1) + '-0' + date.getDate();
            return date.getFullYear() + '-' + (date.getMonth() + 1) + '-0' + date.getDate();
        }
    }
})();
