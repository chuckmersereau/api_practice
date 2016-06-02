(function(){
    angular
        .module('mpdxApp')
        .constant('moment', window.moment)
        .constant('_', window._)
        .constant('__', window.__)
        .constant('$', window.$);
})();
