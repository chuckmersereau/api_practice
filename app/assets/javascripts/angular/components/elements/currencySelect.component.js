(function(){
    angular
    .module('mpdxApp')
    .component('currencySelect', {
        templateUrl: '/templates/elements/currencySelect.html',
        controller: currencySelectController,
        require: {
            ngModel: 'ngModel'
        }
    });

    currencySelectController.$inject = ['twitterCldr'];

    function currencySelectController(twitterCldr) {
        var vm = this;
        vm.currencies = [];

        vm.$onInit = $onInit;
        vm.currencySelected = currencySelected;

        activate();

        function $onInit() {
            var ngModel = vm.ngModel;
            ngModel.$render = onChange;
        }

        function onChange() {
            vm.selectedCurrency = vm.ngModel.$viewValue;
        }

        function currencySelected() {
            vm.ngModel.$setViewValue(vm.selectedCurrency);
        }

        function activate() {
            vm.currencies = _.values(twitterCldr.Currencies.currencies);
        }
    }
})();
