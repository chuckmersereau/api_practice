angular.module('mpdxApp').filter('gettext', function(__){
  return function (val) {
    return __ && val ? __(val) : val;
  };
});
