describe('contacts', function() {
    beforeEach(module('mpdxApp'));
    var self = {};

    beforeEach(inject(function($injector, $componentController, api) {
        self.api = api;
        $httpBackend = $injector.get('$httpBackend');
        var $rootScope = $injector.get('$rootScope');
        var $scope = $rootScope.$new();

        self.controller = $componentController('salaryCurrencyDonationsReport', {
            '$scope': $scope,
            '$http': $httpBackend
        });
    }));

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

    describe('aggregateDonorDonations', function() {
        it('should add an aggregates object to each donor that contains a sum, average, and min', function () {
            var donors = [
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        {
                            "converted_amount": 10.0
                        },
                        {
                            "converted_amount": 20.0
                        },
                        {
                            "converted_amount": 40.0
                        }
                    ]
                }
            ];

            expect(self.controller._aggregateDonorDonations(donors)).toEqual([
                {
                    donorInfo: donors[0].donorInfo,
                    donations: donors[0].donations,
                    aggregates: {
                        sum: 70,
                        average: 70 / 12,
                        min: 10
                    }
                }
            ]);
        });
    });

    describe('addMissingMonths', function() {
        it('should add empty donations for months with missing donations', function () {
            var donors = [
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        {
                            "converted_amount": 10.0,
                            "donation_date": "2015-04-01"
                        },
                        {
                            "converted_amount": 20.0,
                            "donation_date": "2015-01-31"
                        }
                    ]
                }
            ];

            var allMonths = ["2015-01", "2015-02", "2015-03", "2015-04"];

            expect(self.controller._addMissingMonths(donors, allMonths)).toEqual([
                {
                    donorInfo: donors[0].donorInfo,
                    donations: [
                        {
                            "converted_amount": 20.0,
                            "donation_date": "2015-01-31"
                        },
                        {
                            "converted_amount": 0.0,
                            "donation_date": "2015-02-01"
                        },
                        {
                            "converted_amount": 0.0,
                            "donation_date": "2015-03-01"
                        },
                        {
                            "converted_amount": 10.0,
                            "donation_date": "2015-04-01"
                        }
                    ]
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
                            "converted_amount": 10.0,
                            "donation_date": "2015-01-25"
                        },
                        {
                            "converted_amount": 20.0,
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
                            "converted_amount": 30.0,
                            "donation_date": "2015-01-31"
                        },
                        {
                            "converted_amount": 40.0,
                            "donation_date": "2015-02-10"
                        }
                    ]
                }
            ];

            var allMonths = ["2015-01", "2015-02"];

            expect(self.controller._sumMonths(donors, allMonths)).toEqual([40, 60]);
        });
    });

    describe('parseReportInfo', function() {
        it('should group donations by donor, sort them by name, aggregate each donor, and add empty donations for missing months', function () {
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
                        "converted_amount": 175.0,
                        "contact_id": 8,
                        "donation_date": "2015-01-31"
                    },
                    {
                        "converted_amount": 100.0,
                        "contact_id": 7,
                        "donation_date": "2015-01-01"
                    },
                    {
                        "converted_amount": 175.0,
                        "contact_id": 8,
                        "donation_date": "2015-02-01"
                    },
                    {
                        "converted_amount": 100.0,
                        "contact_id": 7,
                        "donation_date": "2015-03-31"
                    }
                ]
            };

            var allMonths = ["2015-01", "2015-02", "2015-03"];

            expect(self.controller._parseReportInfo(reportInfo, allMonths)).toEqual([
                {
                    donorInfo: {
                        "id": 8,
                        "name": "Bird, Tweety and Tweetilee"
                    },
                    donations: [
                        { converted_amount: 175, contact_id: 8, donation_date: '2015-01-31' },
                        { converted_amount: 175, contact_id: 8, donation_date: '2015-02-01' },
                        { converted_amount: 0, donation_date: '2015-03-01' }
                    ],
                    aggregates: {
                        sum: 350,
                        average: 29.166666666666668,
                        min: 175
                    }
                },
                {
                    donorInfo: {
                        "id": 7,
                        "name": "Dalmation, Pongo and Perdita"
                    },
                    donations: [
                        { converted_amount: 100, contact_id: 7, donation_date: '2015-01-01' },
                        { converted_amount: 0, donation_date: '2015-02-01' },
                        { converted_amount: 100, contact_id: 7, donation_date: '2015-03-31' }
                    ],
                    aggregates: {
                        sum: 200,
                        average: 16.666666666666668,
                        min: 100
                    }
                }
            ]);
        });
    });
});
