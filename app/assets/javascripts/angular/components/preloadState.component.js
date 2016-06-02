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
            if(vm.data === 'true' || vm.data === 'false')
                state[vm.name] = vm.data === 'true';
            else
                state[vm.name] = vm.data;
        }
    }
})();
