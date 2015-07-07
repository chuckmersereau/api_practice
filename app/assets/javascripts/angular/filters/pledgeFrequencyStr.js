angular.module('mpdxApp').filter('pledgeFrequencyStr', function(){
  return function (val) {
    switch(val) {
      case '0.23076923076923':
        return 'Weekly';
      case '0.46153846153846':
        return 'Fortnightly';
      case '1':
        return 'Monthly';
      case '2':
        return 'Bi-Monthly';
      case '3':
        return 'Quarterly';
      case '4':
        return 'Quad-Monthly';
      case '6':
        return 'Semi-Annual';
      case '12':
        return 'Annual';
      case '24':
        return 'Biennial';
    }
  };
});
