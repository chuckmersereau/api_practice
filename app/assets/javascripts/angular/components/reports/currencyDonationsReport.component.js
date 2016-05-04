(function(){
    angular
        .module('mpdxApp')
        .component('currencyDonationsReport', {
            controller: currencyDonationsReportController,
            templateUrl: '/templates/reports/currencyDonations.html',
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
        vm.useConvertedValues = vm.type === 'salary';

        var monthsBefore = 11;
        vm.sumOfAllCurrenciesConverted = 0;

        vm.moment = moment;
        vm.errorOccurred = false;
        vm.loading = true;
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
                vm.sumOfAllCurrenciesConverted = _.sumBy(vm.currencyGroups, 'yearTotalConverted');
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
                    return processCurrencyGroup(currencyGroup, reportInfo.donors, allMonths);
                })
                .orderBy('yearTotalConverted', 'desc')
                .value();
        }

        function processCurrencyGroup(currencyGroup, rawDonors, allMonths){
            var donors = _(rawDonors)
                .groupDonationsByDonor(currencyGroup.donations)
                .filter('donations') //removes donors with no donations in current currency
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
                currencyConverted: currencyGroup.currencyConverted,
                currencySymbol: currencyGroup.currencySymbol,
                currencySymbolConverted: currencyGroup.currencySymbolConverted,
                donors: donors,
                monthlyTotals: monthlyTotals,
                yearTotal: _.sumBy(monthlyTotals, 'amount'),
                yearTotalConverted: _.sumBy(monthlyTotals, 'amountConverted')
            };
        }

        function groupDonationsByCurrency(donations){
            var groupedDonationsByCurrency = _.groupBy(donations, vm.useConvertedValues ? 'converted_currency' : 'currency');
            return _.map(groupedDonationsByCurrency, function(donations, currency){
                return {
                    currency: donations[0]['currency'],
                    currencyConverted: donations[0]['converted_currency'],
                    currencySymbol: donations[0]['currency_symbol'],
                    currencySymbolConverted: donations[0]['converted_currency_symbol'],
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
                .filter(function(donation){
                    // The API data includes a full 12 previous months plus the
                    // current month, but we only show 11 previous months plus
                    // the current month in the report, so exclude donations
                    // that are not in the report date range.
                    donation.donation_month = moment(donation.donation_date).format('YYYY-MM');
                    return _.includes(vm.allMonths, donation.donation_month);

                })
                .groupBy('donation_month')
                .map(function(donationsInMonth, month){
                    return {
                        amount: _.sumBy(donationsInMonth, 'amount'),
                        amountConverted: _.sumBy(donationsInMonth, 'converted_amount'),
                        currency: donationsInMonth[0]['currency'],
                        currencyConverted: donationsInMonth[0]['converted_currency'],
                        currencySymbol: donationsInMonth[0]['currency_symbol'],
                        currencySymbolConverted: donationsInMonth[0]['converted_currency_symbol'],
                        donation_date: month,
                        rawDonations: donationsInMonth
                    }
                })
                .value();
        }

        function aggregateDonorDonationsByYear(donors){
            return _.map(donors, function(donor){
                var sum = _.sumBy(donor.donations, 'amount');
                var sumConverted = _.sumBy(donor.donations, 'amountConverted');
                var minDonation = _.minBy(donor.donations, 'amount');
                var minDonationConverted = _.minBy(donor.donations, 'amountConverted');
                return _.assign(donor, {
                    aggregates: {
                        sum: sum,
                        average: sum / monthsBefore,
                        min: minDonation ? minDonation.amount : 0
                    },
                    aggregatesConverted: {
                        sum: sumConverted,
                        average: sumConverted / monthsBefore,
                        min: minDonationConverted ? minDonation.amountConverted : 0
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
                        amountConverted: 0,
                        donation_date: moment(date).format('YYYY-MM')
                    };
                }
            });
        }

        function sumMonths(donors, allMonths){
            var emptyMonthlyTotals = _.map(allMonths, function() {
                return {
                    amount: 0,
                    amountConverted: 0
                };
            });
            return _.reduce(donors, function(months, donor){
                _.forEach(donor.donations, function(donation, index){
                    months[index].amount += donation.amount;
                    months[index].amountConverted += donation.amountConverted;
                });
                return months;
            }, emptyMonthlyTotals);
        }

        function percentage(currencyTotal){
            if(vm.sumOfAllCurrenciesConverted === 0){
                return 0;
            }
            return currencyTotal / vm.sumOfAllCurrenciesConverted * 100;
        }
    }
})();
