(function() {
    angular
        .module('mpdxApp')
        .factory('state', stateService);

    function stateService(){
        var service = {
            current_currency: '',
            current_currency_symbol: '',
            current_account_list_id: '',
            contact_limit: null
        };

        return service;
    }
})();
