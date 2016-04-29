(function(){
    angular
        .module('mpdxApp')
        .component('preloadState', {
            controller: preloadStateController,
            bindings: {
                'name': '@',
                'data': '@'
            }
        });

    preloadStateController.$inject = ['state'];

    function preloadStateController(state) {
        var vm = this;

        activate();

        function activate() {
            state[vm.name] = vm.data;
        }
    }
})();
