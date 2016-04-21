(function(){
    angular
        .module('mpdxApp')
        .component('appeal', {
            controller: appealController,
            templateUrl: '/templates/appeals/edit.html.erb', //Idk if this is the template you wanted
            bindings: {
                id: '@'
            }
        });

    appealController.$inject = ['api'];

    function appealController(api) {
        var vm = this;

        activate();

        function activate(){
            loadAppeal(vm.id);
        }

        function loadAppeal(id){
            console.log("Loading appeal id:", id);
            //api.call(...)
        }
    }
})();


//Call this anywhere in html using:
//<appeal id="<%= appeal_id %>"></appeal>

//In your template, because components use the controllerAs syntax, you can access vm.id with $ctrl.id
//With controllerAs, vm.id === $scope.$ctrl.id
//You could name $ctrl somethine else like appeal if you wanted https://toddmotto.com/exploring-the-angular-1-5-component-method/
