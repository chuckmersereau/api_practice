/* eslint angular/window-service: "off" */

(function(){
    angular
        .module('mpdxApp')
        .constant('moment', window.moment)
        .constant('_', window._)
        .constant('__', window.__)
        .constant('$', window.$)
        .constant('Gmaps', window.Gmaps)
        .constant('Rx', window.Rx);
})();
