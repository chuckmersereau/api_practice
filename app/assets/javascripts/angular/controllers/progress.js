angular.module('mpdxApp').controller('progressController', function (api) {
    this.dateRange = 'May 11 - May 17'
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
    }
});
