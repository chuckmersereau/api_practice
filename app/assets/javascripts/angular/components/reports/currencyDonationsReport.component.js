(function(){
    angular
        .module('mpdxApp')
        .component('currencyDonationsReport', {
            controller: currencyDonationsReportController,
            templateUrl: '/templates/reports/currencyDonations.html',
            bindings: {
                'type': '@',
                'expanded': '@'
            }
        });

    currencyDonationsReportController.$inject = ['_', 'api', 'state', 'moment', 'monthRange'];

    function currencyDonationsReportController(_, api, state, moment, monthRange) {
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
        vm.type = vm.type || 'salary';

        //Expand all columns
        vm.expanded = vm.expanded || false;

        vm.monthsToShow = 13;
        vm.sumOfAllCurrenciesConverted = 0;

        vm.moment = moment;
        vm.errorOccurred = false;
        vm.loading = true;
        vm.allMonths = monthRange.getPastMonths(vm.monthsToShow);
        vm.years = monthRange.yearsWithMonthCounts(vm.allMonths);
        vm.currencyGroups = [];

        vm.percentage = percentage;
        vm.toggleReportType = toggleReportType;
        vm.currencyGroupsToCSV = currencyGroupsToCSV;

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
                vm.rawReportInfo = data.report_info;
                updateReport();
                vm.loading = false;
            }, function() {
                vm.errorOccurred = true;
                vm.loading = false;
            });
        }

        function toggleReportType(){
            vm.type = vm.type === 'donor' ? 'salary' : 'donor';
            updateReport();
        }

        function updateReport(){
            vm.useConvertedValues = vm.type === 'salary';
            vm.currencyGroups = parseReportInfo(vm.rawReportInfo, vm.allMonths);
            vm.sumOfAllCurrenciesConverted = _.sumBy(vm.currencyGroups, 'yearTotalConverted');
        }

        function parseReportInfo(reportInfo, allMonths){
            _.mixin({
                groupDonationsByCurrency: groupDonationsByCurrency,
                groupDonationsByDonor: groupDonationsByDonor,
                aggregateDonationsByMonth: aggregateDonationsByMonth,
                aggregateDonorDonationsByYear: aggregateDonorDonationsByYear
            });

            return _(reportInfo.donations)
                .filter(function(donation) {
                    //Filter out donations that are before the monthsToShow range
                    return moment(donation.donation_date).isSameOrAfter(monthRange.getStartingMonth(vm.monthsToShow));
                })
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
            // Exclude last month since it may be incomplete
            var monthlyTotalsWithoutCurrentMonth = _.dropRight(monthlyTotals, 1);
            return {
                currency: currencyGroup.currency,
                currencyConverted: currencyGroup.currencyConverted,
                currencySymbol: currencyGroup.currencySymbol,
                currencySymbolConverted: currencyGroup.currencySymbolConverted,
                donors: donors,
                monthlyTotals: monthlyTotals,
                yearTotal: _.sumBy(monthlyTotalsWithoutCurrentMonth, 'amount'),
                yearTotalConverted: _.sumBy(monthlyTotalsWithoutCurrentMonth, 'amountConverted')
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
                .groupBy(function(donation){
                    return moment(donation.donation_date).format('YYYY-MM');
                })
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
                // Filter out current month which may not be complete for every donor
                var donationsWithoutCurrentMonth = _.filter(donor.donations, function(donation){
                    return !moment().isSame(donation.donation_date, 'month');
                });

                // Calculate the average based on the first gift the partner made this year
                // which works better for people who started giving recently.
                var firstDonationMonth = _.minBy(donor.donations, 'donation_date').donation_date;
                // Diff purposely excludes current month
                var donationMonths = moment().diff(firstDonationMonth, 'months');

                var sum = _.sumBy(donationsWithoutCurrentMonth, 'amount');
                var sumConverted = _.sumBy(donationsWithoutCurrentMonth, 'amountConverted');
                var minDonation = _.minBy(donor.donations, 'amount');
                var minDonationConverted = _.minBy(donor.donations, 'amountConverted');

                return _.assign(donor, {
                    aggregates: {
                        sum: sum,
                        average: sum / donationMonths,
                        min: minDonation ? minDonation.amount : 0
                    },
                    aggregatesConverted: {
                        sum: sumConverted,
                        average: sumConverted / donationMonths,
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

        function currencyGroupsToCSV(){
            var csvHeaders = _.flatten([
                'Partner',
                'Status',
                'Pledge',
                'Average',
                'Minimum',
                vm.allMonths,
                'Total (last month excluded from total)'
            ]);
            var converted = vm.useConvertedValues ? 'Converted' : '';

            var output = _.flatMap(vm.currencyGroups, function (currencyGroup){
                var currencyHeaders = [
                    [
                        'Currency',
                        currencyGroup['currency' + converted],
                        currencyGroup['currencySymbol' + converted]
                    ],
                    csvHeaders
                ];
                var donorRows = _.map(currencyGroup.donors, function(donor){
                    return _.concat(
                        donor.donorInfo.name,
                        donor.donorInfo.status,
                        currencyGroup.currencySymbol + donor.donorInfo.pledge_amount + ' ' + currencyGroup.currency + ' ' + donor.donorInfo.pledge_frequency,
                        _.round(donor['aggregates' + converted].average, 2),
                        donor['aggregates' + converted].min,
                        _.map(donor.donations, 'amount' + converted),
                        donor['aggregates' + converted].sum
                    );
                });
                var totals = _.concat('Totals', _.times(4, _.constant('')), _.map(currencyGroup.monthlyTotals, 'amount' + converted), currencyGroup['yearTotal' + converted]);
                return _.concat(currencyHeaders, donorRows, [totals], null);
            });
            return output;
        }
    }
})();
