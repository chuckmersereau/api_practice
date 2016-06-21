angular.module('mpdxApp').filter('pledgeFrequencyStr', function(){
  return function (val) {
    val = parseFloat(val);
    switch(val) {
      case 0.23076923076923:
        return __('Weekly');
      case 0.46153846153846:
        return __('Every 2 Weeks');
      case 1:
        return __('Monthly');
      case 2:
        return __('Every 2 Months');
      case 3:
        return __('Quarterly');
      case 4:
        return __('Every 4 Months');
      case 6:
        return __('Every 6 Months');
      case 12:
        return __('Annual');
      case 24:
        return __('Every 2 Years');
    }
  };
});
