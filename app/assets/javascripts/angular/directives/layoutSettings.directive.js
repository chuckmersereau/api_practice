(function(){
    angular
        .module('mpdxApp')
        .directive('layoutSettings', function(){
            return {
                restrict: 'A',
                controller: layoutSettingsController,
                controllerAs: '$layoutSettingsCtrl',
                bindToController: true
            };
        });

    layoutSettingsController.$inject = ['layoutSettings'];

    function layoutSettingsController(layoutSettings) {
        var vm = this;

        vm.layoutSettings = layoutSettings;
    }
})();
