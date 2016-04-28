(function(){
    angular
    .module('mpdxApp')
    .component('donorCurrencyDonationsReport', {
        controller: donorCurrencyDonationsReportController,
        templateUrl: '/templates/reports/donorCurrencyDonations.html'
    });

    donorCurrencyDonationsReportController.$inject = ['api'];

    function donorCurrencyDonationsReportController(api) {
        var vm = this;
        vm.loading = true;
        vm.errorOccurred = false;
        vm.monthsBack = 12;
        vm.pastMonthDates = pastMonthDates(vm.monthsBack);
        vm.yearsWithMonthCounts = yearsWithMonthCounts(vm.pastMonthDates);
        vm.currencyMonthlyTotals = {};

        activate();

        function activate() {
            api.call('get', 'reports/year_donations', {}, function(data) {
                groupDonationsAndDonorsByCurrency(
                    data.report_info.donations, data.report_info.donors
                );
                vm.loading = false;
            }, function() {
                vm.errorOccurred = true;
                vm.loading = false;
            });
        }

        function donorTooltip(currency, currencySymbol, donorAndDonations) {
            var donor = donorAndDonations.donor;
            var tooltip = "";
            if (donor.pledge_amount === null || donor.pledge_amount <= 0.0) {
                if (donor.status !== null && donor.status != "") {
                    tooltip += donor.status + ". ";
                }
            } else {
                tooltip +=
                    __('Commitment ') +
                        currencySymbol + donor.pledge_amount + ' ' + currency +
                            ' ' + donor.pledge_frequency + ". ";
            }
            tooltip +=
                __('Avg.') + ' ' + currencySymbol + Math.round(donorAndDonations.average) +
                    ' / ' +
                        __('Min.') + ' ' + currencySymbol + Math.round(donorAndDonations.min);
                        return tooltip;
        }

        function addToCurrencyMonthlyTotals(currency, monthlyTotals) {
            for (var monthIndex in monthlyTotals) {
                vm.currencyMonthlyTotals[currency][monthIndex] +=
                    monthlyTotals[monthIndex];
            }
        }

        function groupDonationsAndDonorsByCurrency(donations, donors) {
            vm.donorsById = _.groupBy(donors, 'id');
            vm.donorsAndDonationsByCurrency = {};
            vm.currencySymbols = {};
            vm.convertedTotalsByCurrency = {};
            vm.convertedCurrency = donations[0].converted_currency;
            vm.convertedCurrencySymbol = donations[0].converted_currency_symbol;

            var donationsByCurrency = _.groupBy(donations, 'currency');
            for (var currency in donationsByCurrency) {
                groupDonorsAndDonations(currency, donationsByCurrency);
            }
            generateCurrencyAggregates(donationsByCurrency);
        }

        function generateCurrencyAggregates(donationsByCurrency) {
            var overallConvertedTotal = 0.0;
            var convertedTotalsByCurrency = {};
            var totalsByCurrency = {};
            for (var currency in donationsByCurrency) {
                var donations = donationsByCurrency[currency];
                var convertedTotal = _.sum(_.map(donations, 'converted_amount'))
                convertedTotalsByCurrency[currency] = convertedTotal;
                overallConvertedTotal += convertedTotal;
                totalsByCurrency[currency] = _.sum(_.map(donations, 'amount'));
            }
            vm.currencyAggregates = [];
            for (var currency in donationsByCurrency) {
                var convertedTotal = convertedTotalsByCurrency[currency];
                var currencyAggregate = {
                    currency: currency,
                    currencySymbol: vm.currencySymbols[currency],
                    total: totalsByCurrency[currency],
                    convertedTotal: convertedTotal,
                    convertedPercent: convertedTotal / overallConvertedTotal * 100.0
                }
                currencyAggregate.tooltip =
                    currencyTooltip(currencyAggregate, overallConvertedTotal);
                vm.currencyAggregates.push(currencyAggregate);
            }
        }

        function currencyTooltip(aggregate, overallConvertedTotal) {
            return __('Total') + ' ' +
                aggregate.currencySymbol +
                Math.round(aggregate.total) + ' ' + aggregate.currency + ' ' +
                __('converted as') + ' ' + vm.convertedCurrencySymbol +
                Math.round(aggregate.convertedTotal) + ' ' + vm.convertedCurrency +
                ' (' + Math.round(aggregate.convertedPercent) + '% ' + __('of total') +
                ' ' + vm.convertedCurrencySymbol + Math.round(overallConvertedTotal) +
                ' ' + vm.convertedCurrency + ')';
        }

        function groupDonorsAndDonations(currency, donationsByCurrency) {
            vm.currencyMonthlyTotals[currency] = {};
            for (var i = 0; i < vm.monthsBack; i++) {
                vm.currencyMonthlyTotals[currency][i] = 0.0;
            }

            var donations = donationsByCurrency[currency];
            vm.currencySymbols[currency] = donations[0].currency_symbol;

            var donationsByContactId = _.groupBy(donations, 'contact_id');
            vm.donorsAndDonationsByCurrency[currency] = [];
            for (var contactId in donationsByContactId) {
                vm.donorsAndDonationsByCurrency[currency].push(
                    donorsAndDonationsForContact(currency, contactId, donationsByContactId));
            }
        }

        function donorsAndDonationsForContact(currency, contactId, donationsByContactId) {
            donations = donationsByContactId[contactId];
            var amountsByMonthsAgo = donationMonthlyTotals(donations, vm.monthsBack);
            var monthlyAmounts = [];
            for (var monthsAgo in amountsByMonthsAgo) {
                var amount = amountsByMonthsAgo[monthsAgo];
                if (!isNaN(amount)) {
                    monthlyAmounts.push(amount);
                }
            }
            addToCurrencyMonthlyTotals(currency, amountsByMonthsAgo);
            var totalDonations = _.sum(monthlyAmounts);
            var donorAndDonations = {
                donor: vm.donorsById[contactId][0],
                amountsByMonthsAgo: amountsByMonthsAgo,
                total: totalDonations,
                average: totalDonations / vm.monthsBack,
                min: _.min(monthlyAmounts)
            }
            var currencySymbol = vm.currencySymbols[currency];
            donorAndDonations.tooltip =
                donorTooltip(currency, currencySymbol, donorAndDonations);
            return donorAndDonations;
        }


        //***** Date Functions *****//
        var currentMonthIndex = monthIndex(new Date());

        function monthsAgo(dateStr) {
            return currentMonthIndex - monthIndex(new Date(dateStr));
        }

        function pastMonthDates(monthsBack) {
            var monthsBackDates = [];
            for (var i = monthsBack - 1; i >= 0; i--) {
                var current = new Date();
                var date = new Date(current.setMonth(current.getMonth() - i));
                monthsBackDates.push(date);
            }
            return monthsBackDates;
        }

        function yearsWithMonthCounts(monthDates) {
            var datesByYear = _.groupBy(monthDates, function(date) {
                return date.getFullYear();
            });
            for (var year in datesByYear) {
                datesByYear[year] = datesByYear[year].length;
            }
            return datesByYear;
        }

        function donationMonthlyTotals(donations, monthsBack) {
            var monthlyTotals = {};
            for (var i = 0; i < monthsBack; i++) {
                monthlyTotals[i] = 0.0;
            }
            if (angular.isUndefined(donations)) {
                return monthlyTotals;
            }
            donations.forEach(function(donation) {
                var monthIndex = monthsBack - monthsAgo(donation.donation_date);
                if (monthIndex < monthsBack && monthIndex >= 0) {
                    monthlyTotals[monthIndex] += donation.amount;
                }
            });
            return monthlyTotals;
        }

        function monthIndex(date) {
            return date.getYear() * 12 + date.getMonth();
        }
    }
})();
