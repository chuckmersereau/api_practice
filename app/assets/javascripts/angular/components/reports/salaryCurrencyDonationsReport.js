(function(){
    angular
        .module('mpdxApp')
        .component('currencyDonationsReport', {
            controller: currencyDonationsReportController,
            templateUrl: '/templates/reports/salaryCurrencyDonations.html',
            bindings: {
                'type': '@'
            }
        });

    currencyDonationsReportController.$inject = ['api', 'state', 'moment', 'monthRange'];

    function currencyDonationsReportController(api, state, moment, monthRange) {
        var vm = this;

        /**
        Report Types
        The type binding can be 'donor' or 'salary'
        - Donor
          Donors are grouped by the currency they gave in
          The normal amount and currency fields are used
        - Salary
          Donors are grouped into a single category which is the user's salary currency
          The converted amount and currency fields are used (using 'converted_' prefix)
         **/
        var converted = '';
        if(vm.type === 'salary'){
            converted = 'converted_';
        }

        var monthsBefore = 12;
        var sumOfAllCurrencies = 0;

        vm.moment = moment;
        vm.errorOccurred = false;
        vm.allMonths = monthRange.getPastMonths(monthsBefore);
        vm.years = monthRange.yearsWithMonthCounts(vm.allMonths);
        vm.currencyGroups = [];

        vm.percentage = percentage;

        vm._parseReportInfo = parseReportInfo;
        vm._groupDonationsByCurrency = groupDonationsByCurrency;
        vm._groupDonationsByDonor = groupDonationsByDonor;
        vm._aggregateDonationsByMonth = aggregateDonationsByMonth;
        vm._aggregateDonorDonationsByYear = aggregateDonorDonationsByYear;
        vm._addMissingMonths = addMissingMonths;
        vm._sumMonths = sumMonths;

        activate();

        function activate() {
            var url = 'reports/year_donations?account_list_id=' + state.current_account_list_id;
            api.call('get', url, {}, function(data) {
                vm.currencyGroups = parseReportInfo(data.report_info, vm.allMonths);
                sumOfAllCurrencies = _.sumBy(vm.currencyGroups, 'yearTotal'); //TODO: use converted values for this
                vm.loading = false;
            }, function() {
                vm.errorOccurred = true;
                vm.loading = false;
            });
        }

        function parseReportInfo(reportInfo, allMonths){
            _.mixin({
                groupDonationsByCurrency: groupDonationsByCurrency,
                groupDonationsByDonor: groupDonationsByDonor,
                aggregateDonationsByMonth: aggregateDonationsByMonth,
                aggregateDonorDonationsByYear: aggregateDonorDonationsByYear
            });

            return _(reportInfo.donations)
                .groupDonationsByCurrency()
                .map(function(currencyGroup){
                    var donors = _(reportInfo.donors)
                        .groupDonationsByDonor(currencyGroup.donations)
                        .filter('donations') //remove donors with no donations in current currency
                        .sortBy('donorInfo.name')
                        .map(function(donor){
                            //parse each donor's donations
                            donor.donations = _(donor.donations)
                                .aggregateDonationsByMonth()
                                .value();
                            return donor;
                        })
                        .aggregateDonorDonationsByYear()
                        .map(function(donor) {
                            donor.donations = addMissingMonths(donor.donations, allMonths);
                            return donor;
                        })
                        .value();
                    var monthlyTotals = sumMonths(donors, allMonths);
                    return {
                        currency: currencyGroup.currency,
                        currencySymbol: currencyGroup.currencySymbol,
                        donors: donors,
                        monthlyTotals: monthlyTotals,
                        yearTotal: _.sum(monthlyTotals)
                    };
                })
                .orderBy('yearTotal', 'desc')
                .value();
        }

        function groupDonationsByCurrency(donations){
            var groupedDonationsByCurrency = _.groupBy(donations, converted + 'currency');
            return _.map(groupedDonationsByCurrency, function(donations, currency){
                return {
                    currency: currency,
                    currencySymbol: donations[0][converted + 'currency_symbol'],
                    donations: donations
                }
            });
        }

        function groupDonationsByDonor(donors, donations){
            var groupedDonations = _.groupBy(donations, 'contact_id');
            return _.map(donors, function(donor){
                return {
                    donorInfo: donor,
                    donations: groupedDonations[donor.id]
                }
            });
        }

        function aggregateDonationsByMonth(donations){
            return _(donations)
                .groupBy(function(donation){
                    return moment(donation.donation_date).format('YYYY-MM')
                })
                .map(function(donationsInMonth, month){
                    return {
                        amount: _.sumBy(donationsInMonth, converted + 'amount'),
                        donation_date: month,
                        rawDonations: donationsInMonth
                    }
                })
                .value();
        }

        function aggregateDonorDonationsByYear(donors){
            return _.map(donors, function(donor){
                var sum = _.sumBy(donor.donations, 'amount');
                var minDonation = _.minBy(donor.donations, 'amount');
                return _.assign(donor, {
                    aggregates: {
                        sum: sum,
                        average: sum / monthsBefore,
                        min: minDonation ? minDonation.amount : 0
                    }
                })
            });
        }

        function addMissingMonths(donations, allMonths){
            return _.map(allMonths, function (date) {
                var existingDonation = _.find(donations, function(donation){
                    return moment(donation.donation_date).isSame(date, 'month');
                });
                if(existingDonation){
                    return existingDonation;
                }else{
                    return {
                        amount: 0,
                        donation_date: moment(date).format('YYYY-MM')
                    };
                }
            });
        }

        function sumMonths(donors, allMonths){
            return _.reduce(donors, function(months, donor){
                _.forEach(donor.donations, function(donation, index){
                    months[index] += donation.amount;
                });
                return months;
            }, _.map(allMonths, _.constant(0)));
        }

        function percentage(currencyTotal){
            if(sumOfAllCurrencies === 0){
                return 0;
            }
            return currencyTotal / sumOfAllCurrencies * 100;
        }
    }
})();
