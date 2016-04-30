(function(){
    angular
        .module('mpdxApp')
        .component('salaryCurrencyDonationsReport', {
            controller: salaryCurrencyDonationsReportController,
            templateUrl: '/templates/reports/salaryCurrencyDonations.html'
        });

    salaryCurrencyDonationsReportController.$inject = ['api', 'state', 'moment', 'monthRange'];

    function salaryCurrencyDonationsReportController(api, state, moment, monthRange) {
        var vm = this;

        vm.moment = moment;
        vm.errorOccurred = false;
        vm.allMonths = monthRange.allMonths;
        vm.years = monthRange.yearsWithMonthCounts;
        vm.donors = [];
        vm.monthlyTotals = [];
        vm.currentCurrency = state.current_currency;
        vm.currentCurrencySymbol = state.current_currency_symbol;

        vm._parseReportInfo = parseReportInfo;
        vm._groupDonationsByDonor = groupDonationsByDonor;
        vm._aggregateDonorDonations = aggregateDonorDonations;
        vm._addMissingMonths = addMissingMonths;
        vm._sumMonths = sumMonths;

        activate();

        function activate() {
            var url = 'reports/year_donations?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
                vm.donors = parseReportInfo(data.report_info, monthRange.allMonths);
                vm.monthlyTotals = sumMonths(vm.donors, monthRange.allMonths);
                vm.yearTotal = _.sum(vm.monthlyTotals);
                vm.loading = false;
            }, function() {
                vm.errorOccurred = true;
                vm.loading = false;
            });
        }

        function parseReportInfo(reportInfo, allMonths){
            _.mixin({
                groupDonationsByDonor: groupDonationsByDonor,
                aggregateDonorDonations: aggregateDonorDonations,
                addMissingMonths: addMissingMonths
            });

            return _(reportInfo.donors)
                .groupDonationsByDonor(reportInfo.donations)
                .sortBy('donorInfo.name')
                .aggregateDonorDonations()
                .addMissingMonths(allMonths)
                .value();
        }

        function groupDonationsByDonor(donors, donations){
            return _.map(donors, function(donor){
                return {
                    donorInfo: donor,
                    donations: _.filter(donations, {contact_id: donor.id})
                }
            });
        }

        function aggregateDonorDonations(donors){
            return _.map(donors, function(donor){
                var sum = _.sumBy(donor.donations, 'converted_amount');
                return _.assign(donor, {
                    aggregates: {
                        sum: sum,
                        average: sum / 12, //TODO: replace 12 with monthsBack
                        min: _.minBy(donor.donations, 'converted_amount').converted_amount
                    }
                })
            });
        }

        function addMissingMonths(donors, allMonths){
            return _.map(donors, function(donor){
                donor.donations = _.map(allMonths, function (date) {
                    var existingDonation = _.find(donor.donations, function(donation){
                        return moment(donation.donation_date).isSame(date, 'month');
                    });
                    if(existingDonation){
                        return existingDonation;
                    }else{
                        return {
                            converted_amount: 0,
                            donation_date: moment(date).format('YYYY-MM-DD')
                        };
                    }
                });
                return donor;
            });
        }

        function sumMonths(donors, allMonths){
            return _.reduce(donors, function(months, donor){
                _.forEach(donor.donations, function(donation, index){
                    months[index] += donation.converted_amount;
                });
                return months;
            }, _.map(allMonths, _.constant(0)));
        }
    }
})();
