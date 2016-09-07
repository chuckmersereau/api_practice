angular.module('mpdxApp').filter('ignoreTimezone', function(){
    return function (val) {
        if (val != null && val.length > 16) {
            return val.substring(0, 16);
        }
        return val;
    };
});
