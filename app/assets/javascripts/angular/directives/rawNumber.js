(function(){
    angular
        .module('mpdxApp')
        .directive('rawNumber', function() {
            return {
                require: 'ngModel',
                link: function(_scope, _element, _attrs, ngModel) {
                    ngModel.$parsers = [];
                    ngModel.$formatters = [];
                }
            };
        });
}());
