angular.module('mpdxApp').filter('gettext', function(){
  return function (val) {
    return window.__ && val ? __(val) : val
  };
});
