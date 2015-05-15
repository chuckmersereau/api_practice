angular.module('mpdxApp').controller('progressController', function (api) {
    var monthNames = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];

    this.start_date = new Date();
    this.start_date.setHours(0,0,0,0);
    this.start_date.setDate(this.start_date.getDate() - this.start_date.getDay());
    this.end_date = new Date(this.start_date);
    this.end_date.setDate(this.start_date.getDate() + 7);
    this.data = {
        contacts: {
            active: 10,
            referrals_on_hand: 6,
            referrals_gained: 5
        },
        appointments: 1,
        phone: {
            completed: 5,
            attempted: 1,
            received: 0,
            appointments: 2,
            talktoinperson: 2
        },
        email: {
            sent: 0,
            received: 0
        },
        facebook: {
            sent: 0,
            received: 0
        },
        text_message: {
            sent: 0,
            received: 0
        },
        electronic: {
            sent: 1,
            received: 6,
            appointments: 3
        },
        appointments: {
            completed: 0
        },
        correspondence: {
            precall: 11,
            support_letters: 6,
            thank_yous: 3,
            reminders: 3
        }
    };

    this.nextWeek = function() {
        this.start_date.setDate(this.start_date.getDate() + 7);
        this.end_date.setDate(this.end_date.getDate() + 7);
    }

    this.previousWeek = function() {
        this.start_date.setDate(this.start_date.getDate() - 7);
        this.end_date.setDate(this.end_date.getDate() - 7);
    }
});
