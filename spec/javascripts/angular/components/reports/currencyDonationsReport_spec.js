describe('contacts', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($injector, $componentController, api) {
        self.api = api;
        $httpBackend = $injector.get('$httpBackend');
        var $rootScope = $injector.get('$rootScope');
        var $scope = $rootScope.$new();

        self.controller = $componentController('currencyDonationsReport', {
            '$scope': $scope,
            '$http': $httpBackend
        });
    }));

    describe('groupDonationsByCurrency', function() {
        it('should group and map an array of donations into objects containing currency info and corresponding donations', function () {
            var donations = [
                {
                    "amount": 175.0,
                    "currency": 'USD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$'
                },
                {
                    "amount": 100.0,
                    "currency": 'USD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$'
                },
                {
                    "amount": 50.0,
                    "currency": 'CAD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$'
                }
            ];

            expect(self.controller._groupDonationsByCurrency(donations)).toEqual([
                {
                    currency: 'USD',
                    currencyConverted: 'USD',
                    currencySymbol: '$',
                    currencySymbolConverted: '$',
                    donations: [ donations[0], donations[1] ]
                },
                {
                    currency: 'CAD',
                    currencyConverted: 'USD',
                    currencySymbol: '$',
                    currencySymbolConverted: '$',
                    donations: [ donations[2] ]
                }
            ]);
        });
    });

    describe('groupDonationsByDonor', function() {
        it('should return an array of objects containing donors and their matching donations', function () {
            var donors = [
                {
                    "id": 7,
                    "name": "Dalmation, Pongo and Perdita"
                },
                {
                    "id": 8,
                    "name": "Bird, Tweety and Tweetilee"
                }
            ];

            var donations = [
                {
                    "converted_amount": 175.0,
                    "contact_id": 8
                },
                {
                    "converted_amount": 100.0,
                    "contact_id": 7

                }
            ];

            expect(self.controller._groupDonationsByDonor(donors, donations)).toEqual([
                {
                    donorInfo: donors[0],
                    donations: [
                        donations[1]
                    ]
                },
                {
                    donorInfo: donors[1],
                    donations: [
                        donations[0]
                    ]
                }
            ]);
        });
    });

    describe('aggregateDonationsByMonth', function() {
        it('should group donations by month, save original donations into rawDonations, and sum them', function () {
            var donations = [
                {
                    "amount": 175.0,
                    "converted_amount": 175.0,
                    "currency": 'USD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$',
                    "contact_id": 8,
                    "donation_date": "2015-01-31"
                },
                {
                    "amount": 25.0,
                    "converted_amount": 25.0,
                    "currency": 'USD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$',
                    "contact_id": 8,
                    "donation_date": "2015-01-05"
                },
                {
                    "amount": 175.0,
                    "converted_amount": 175.0,
                    "currency": 'USD',
                    "currency_symbol": '$',
                    "converted_currency": 'USD',
                    "converted_currency_symbol": '$',
                    "contact_id": 8,
                    "donation_date": "2015-02-01"
                }
            ];

            expect(self.controller._aggregateDonationsByMonth(donations)).toEqual([
                {
                    amount: 200,
                    amountConverted: 200,
                    currency: 'USD',
                    currencyConverted: 'USD',
                    currencySymbol: '$',
                    currencySymbolConverted: '$',
                    donation_date: '2015-01',
                    rawDonations: [ donations[0], donations[1]]
                },
                {
                    amount: 175,
                    amountConverted: 175,
                    currency: 'USD',
                    currencyConverted: 'USD',
                    currencySymbol: '$',
                    currencySymbolConverted: '$',
                    donation_date: '2015-02',
                    rawDonations: [ donations[2] ]
                }
            ]);
        });
    });

    describe('aggregateDonorDonationsByYear', function() {
        it('should add an aggregates object to each donor that contains a sum, average, and min', function () {
            self.controller.reportLastDate = moment('2015-04-15');
            self.controller.reportLastMonth = '2015-04';

            var today = moment('2015-04-01').toDate();
            jasmine.clock().mockDate(today);

            // At this point the donation_date fields have been converted to
            // months.
            var donors = [
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        {
                            "amount": 10.0,
                            "amountConverted": 15.0,
                            "donation_date": '2015-02'
                        },
                        {
                            "amount": 20.0,
                            "amountConverted": 25.0,
                            "donation_date": '2015-03'
                        },
                        {
                            "amount": 40.0,
                            "amountConverted": 45.0,
                            "donation_date": '2015-04'
                        }
                    ]
                }
            ];

            expect(self.controller._aggregateDonorDonationsByYear(donors)).toEqual([
                {
                    donorInfo: donors[0].donorInfo,
                    donations: donors[0].donations,
                    aggregates: {
                        sum: 30,
                        average: 30 / 2,
                        min: 10
                    },
                    aggregatesConverted: {
                        sum: 40,
                        average: 40 / 2,
                        min: 15
                    }
                }
            ]);
        });
    });

    describe('addMissingMonths', function() {
        it('should add empty donations for months with missing donations', function () {
            var donations = [
                {
                    "amount": 10.0,
                    "amountConverted": 15.0,
                    "donation_date": "2015-04"
                },
                {
                    "amount": 20.0,
                    "amountConverted": 25.0,
                    "donation_date": "2015-01"
                }
            ];

            var allMonths = ["2015-01", "2015-02", "2015-03", "2015-04"];

            expect(self.controller._addMissingMonths(donations, allMonths)).toEqual([
                {
                    "amount": 20.0,
                    "amountConverted": 25.0,
                    "donation_date": "2015-01"
                },
                {
                    "amount": 0.0,
                    "amountConverted": 0.0,
                    "donation_date": "2015-02"
                },
                {
                    "amount": 0.0,
                    "amountConverted": 0.0,
                    "donation_date": "2015-03"
                },
                {
                    "amount": 10.0,
                    "amountConverted": 15.0,
                    "donation_date": "2015-04"
                }
            ]);
        });
    });

    describe('sumMonths', function() {
        it('should return an array of sums for each month', function () {
            var donors = [
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        {
                            "amount": 10.0,
                            "amountConverted": 15.0,
                            "donation_date": "2015-01-25"
                        },
                        {
                            "amount": 20.0,
                            "amountConverted": 25.0,
                            "donation_date": "2015-02-01"
                        }
                    ]
                },
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        {
                            "amount": 30.0,
                            "amountConverted": 35.0,
                            "donation_date": "2015-01-31"
                        },
                        {
                            "amount": 40.0,
                            "amountConverted": 45.0,
                            "donation_date": "2015-02-10"
                        }
                    ]
                }
            ];

            var allMonths = ["2015-01", "2015-02"];

            expect(self.controller._sumMonths(donors, allMonths)).toEqual(
                [ { amount: 40, amountConverted: 50 }, { amount: 60, amountConverted: 70 } ]
            );
        });
    });

    describe('parseReportInfo', function() {
        it('groups donations by donor, sort them by name, aggregate each donor, and add empty donations for missing months', function () {
            self.controller.reportLastDate = moment('2015-03-15');
            self.controller.reportLastMonth = '2015-03';
            self.controller.monthsToShow = 11;

            var reportInfo = {
                donors: [
                    {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    {
                        "id": 8,
                        "name": "Bird, Tweety and Tweetilee"
                    }
                ],
                donations: [
                    {
                        "amount": 175.0,
                        "converted_amount": 180.0,
                        "contact_id": 8,
                        "donation_date": "2015-01-31",
                        "currency": 'USD',
                        "currency_symbol": '$',
                        "converted_currency": 'USD',
                        "converted_currency_symbol": '$'
                    },
                    {
                        "amount": 25.0,
                        "converted_amount": 30.0,
                        "contact_id": 8,
                        "donation_date": "2015-01-05",
                        "currency": 'USD',
                        "currency_symbol": '$',
                        "converted_currency": 'USD',
                        "converted_currency_symbol": '$'
                    },
                    {
                        "amount": 100.0,
                        "converted_amount": 105.0,
                        "contact_id": 7,
                        "donation_date": "2015-01-01",
                        "currency": 'USD',
                        "currency_symbol": '$',
                        "converted_currency": 'USD',
                        "converted_currency_symbol": '$'
                    },
                    {
                        "amount": 175.0,
                        "converted_amount": 180.0,
                        "contact_id": 8,
                        "donation_date": "2015-02-01",
                        "currency": 'USD',
                        "currency_symbol": '$',
                        "converted_currency": 'USD',
                        "converted_currency_symbol": '$'
                    },
                    {
                        "amount": 100.0,
                        "converted_amount": 105.0,
                        "contact_id": 7,
                        "donation_date": "2015-03-31",
                        "currency": 'USD',
                        "currency_symbol": '$',
                        "converted_currency": 'USD',
                        "converted_currency_symbol": '$'
                    }
                ]
            };

            var allMonths = ["2015-01", "2015-02", "2015-03"];

            expect(self.controller._parseReportInfo(reportInfo, allMonths)).toEqual([
                {
                    currency: 'USD',
                    currencyConverted: 'USD',
                    currencySymbol: '$',
                    currencySymbolConverted: '$',
                    donors: [
                        {
                            donorInfo: {
                                "id": 8,
                                "name": "Bird, Tweety and Tweetilee"
                            },
                            donations: [
                                {
                                    amount: 200,
                                    amountConverted: 210,
                                    currency: 'USD',
                                    currencyConverted: 'USD',
                                    currencySymbol: '$',
                                    currencySymbolConverted: '$',
                                    donation_date: '2015-01',
                                    rawDonations: [ reportInfo.donations[0], reportInfo.donations[1] ]
                                },
                                {
                                    amount: 175,
                                    amountConverted: 180,
                                    currency: 'USD',
                                    currencyConverted: 'USD',
                                    currencySymbol: '$',
                                    currencySymbolConverted: '$',
                                    donation_date: '2015-02',
                                    rawDonations: [ reportInfo.donations[3] ]
                                },
                                {
                                    amount: 0,
                                    amountConverted: 0,
                                    donation_date: '2015-03'
                                }
                            ],
                            aggregates: {
                                sum: 375,
                                average: 375 / 3,
                                min: 175
                            },
                            aggregatesConverted: {
                                sum: 390,
                                average: 390 / 3,
                                min: 180
                            }
                        },
                        {
                            donorInfo: {
                                "id": 7,
                                "name": "Dalmation, Pongo and Perdita"
                            },
                            donations: [
                                {
                                    amount: 100,
                                    amountConverted: 105,
                                    currency: 'USD',
                                    currencyConverted: 'USD',
                                    currencySymbol: '$',
                                    currencySymbolConverted: '$',
                                    donation_date: '2015-01',
                                    rawDonations: [ reportInfo.donations[2] ]
                                },
                                {
                                    amount: 0,
                                    amountConverted: 0,
                                    donation_date: '2015-02'
                                },
                                {
                                    amount: 100,
                                    amountConverted: 105,
                                    currency: 'USD',
                                    currencyConverted: 'USD',
                                    currencySymbol: '$',
                                    currencySymbolConverted: '$',
                                    donation_date: '2015-03',
                                    rawDonations: [ reportInfo.donations[4] ]
                                }
                            ],
                            aggregates: {
                                sum: 200,
                                average: 200 / 3,
                                min: 100
                            },
                            aggregatesConverted: {
                                sum: 210,
                                average: 70,
                                min: 105
                            }
                        }
                    ],
                    monthlyTotals: [ { amount: 300, amountConverted: 315 }, { amount: 175, amountConverted: 180 }, { amount: 100, amountConverted: 105 } ],
                    yearTotal: 475,
                    yearTotalConverted: 495
                }
            ]);
        });
    });
});
