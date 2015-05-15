angular.module('mpdxApp').controller('progressController', function ($scope, $http, $filter) {
    var monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];
    var scope = this;

    this.start_date = new Date();
    this.start_date.setHours(0,0,0,0);
    this.start_date.setDate(this.start_date.getDate() - this.start_date.getDay() + 1);
    this.end_date = new Date(this.start_date);
    this.end_date.setDate(this.start_date.getDate() + 7);

    var blankData = function() {
        scope.data = {
            contacts: {
                active: '-', referrals_on_hand: '-', referrals: '-'
            },
            appointments: '-',
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

    this.nextWeek = function() {
        this.start_date.setDate(this.start_date.getDate() + 7);
        this.end_date.setDate(this.end_date.getDate() + 7);
        getData();
    }

    this.previousWeek = function() {
        this.start_date.setDate(this.start_date.getDate() - 7);
        this.end_date.setDate(this.end_date.getDate() - 7);
        getData();
    }

    var getData = function() {
        blankData();
        var start_date_string = $filter('date')(scope.start_date, 'yyyy-MM-dd');
        $http.get('/home/progress.json?start_date='+start_date_string).success(function(newData){
            scope.data = newData;
        });
    }
    getData();
});
