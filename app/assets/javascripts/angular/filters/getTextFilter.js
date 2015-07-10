angular.module('mpdxApp').filter('gettext', function(){
  return function (val) {
    return window.__ ? __(val) : val
  };
});
