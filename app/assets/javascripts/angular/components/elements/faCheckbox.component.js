(function(){
    angular
        .module('mpdxApp')
        .component('faCheckbox', {
            controller: faCheckboxController,
            templateUrl: '/templates/elements/faCheckbox.html',
            require: {
                ngModel: 'ngModel'
            }
        });

    faCheckboxController.$inject = [];

    function faCheckboxController() {
        var vm = this;

        vm.$onInit = $onInit;
        vm.toggle = toggle;

        function $onInit() {
            var ngModel = vm.ngModel;
            ngModel.$render = onChange;
        }

        function onChange() {
            vm.checked = vm.ngModel.$viewValue;
        }

        function toggle(){
            vm.checked = !vm.checked;
            vm.ngModel.$setViewValue(vm.checked);
        }
    }
})();
