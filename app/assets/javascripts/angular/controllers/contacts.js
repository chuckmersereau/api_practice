angular.module('mpdxApp').controller('contactsController', function ($scope, $filter, $location, api, contactCache, urlParameter) {
    var viewPrefs;

    $scope.contactsLoading = true;
    $scope.totalContacts = 0;

    $scope.contactQuery = {
        limit: 25,
        page: 1,
        tags: [''],
        name: '',
        type: '',
        activeAddresses: true,
        city: [''],
        state: [''],
        region: [''],
        metro_area: [''],
        newsletter: '',
        status: ['active', 'null'],
        likely: [''],
        church: [''],
        referrer: [''],
        timezone: [''],
        relatedTaskAction: [''],
        appeal: [''],
        pledge_frequencies: [''],
        pledge_received: '',
        contact_info_email: '',
        contact_info_phone: '',
        contact_info_mobile: '',
        contact_info_addr: '',
        contact_info_facebook: '',
        wildcardSearch: urlParameter.get('q'),
        viewPrefsLoaded: false
    };

    $scope.page = {
        current: 1,
        total: 1,
        from: 0,
        to: 0
    };

    $scope.resetFilters = function(){
        $scope.contactQuery.tags = [''];
        $scope.contactQuery.name = '';
        $scope.contactQuery.type = '';
        $scope.contactQuery.activeAddresses = true;
        $scope.contactQuery.city = [''];
        $scope.contactQuery.state = [''];
        $scope.contactQuery.region = [''];
        $scope.contactQuery.metro_area = [''];
        $scope.contactQuery.newsletter = '';
        $scope.contactQuery.status = ['active', 'null'];
        $scope.contactQuery.likely = [''];
        $scope.contactQuery.church = [''];
        $scope.contactQuery.referrer = [''];
        $scope.contactQuery.timezone = [''];
        $scope.contactQuery.relatedTaskAction = [''];
        $scope.contactQuery.appeal = [''];
        $scope.contactQuery.pledge_frequencies = [''];
        $scope.contactQuery.pledge_received = '';
        $scope.contactQuery.wildcardSearch = null;
        $scope.contactQuery.contact_info_email = '';
        $scope.contactQuery.contact_info_phone = '';
        $scope.contactQuery.contact_info_mobile = '';
        $scope.contactQuery.contact_info_addr = '';
        $scope.contactQuery.contact_info_facebook = '';
        if(!_.isNull(document.getElementById('globalContactSearch'))) {
            document.getElementById('globalContactSearch').value = '';
        }
    };

    //view preferences
    api.call('get','users/me', {}, function(data) {
        viewPrefs = data;
        $scope.contactQuery.viewPrefsLoaded = true;

        if(angular.isUndefined(viewPrefs.user.preferences.contacts_filter)){
            var prefs = null;
            viewPrefs.user.preferences.contacts_filter = {};
        }else{
            var prefs = viewPrefs.user.preferences.contacts_filter[window.current_account_list_id];
        }

        if(!_.isNull($scope.contactQuery.wildcardSearch)){
          var prefs = null;
          viewPrefs.user.preferences.contacts_filter = {};
        }

        if(_.isNull(prefs)){
            return;
        }
        if(angular.isDefined(prefs.tags)){
            $scope.contactQuery.tags = prefs.tags.split(',');
        }
        if(angular.isDefined(prefs.type)){
            $scope.contactQuery.type = prefs.type;
            if(prefs.type){
                jQuery("#leftmenu #filter_type").trigger("click");
            }
        }
        if(angular.isDefined(prefs.newsletter)){
            $scope.contactQuery.newsletter = prefs.newsletter;
            if(prefs.newsletter){
                jQuery("#leftmenu #filter_newsletter").trigger("click");
            }
        }
        if(angular.isDefined(prefs.status)){
            $scope.contactQuery.status = prefs.status;
            if(prefs.status[0] !== 'active'){
                jQuery("#leftmenu #filter_status").trigger("click");
            }
        }
        if(angular.isDefined(prefs.likely)){
            $scope.contactQuery.likely = prefs.likely;
            if(prefs.likely[0]){
                jQuery("#leftmenu #filter_likely").trigger("click");
            }
        }
        if(angular.isDefined(prefs.church)){
            $scope.contactQuery.church = prefs.church;
            if(prefs.church[0]){
                jQuery("#leftmenu #filter_church").trigger("click");
            }
        }
        if(angular.isDefined(prefs.referrer)){
            $scope.contactQuery.referrer = prefs.referrer;
            if(prefs.referrer[0]){
                jQuery("#leftmenu #filter_referrer").trigger("click");
            }
        }
        if(angular.isDefined(prefs.timezone)){
          $scope.contactQuery.timezone = prefs.timezone;
          if(prefs.timezone[0]){
            jQuery("#leftmenu #filter_timezone").trigger("click");
          }
        }
        if(angular.isDefined(prefs.relatedTaskAction)){
            $scope.contactQuery.relatedTaskAction = prefs.relatedTaskAction;
            if(prefs.relatedTaskAction[0]){
                jQuery("#leftmenu #filter_relatedTaskAction").trigger("click");
            }
        }
        if(angular.isDefined(prefs.appeal)){
            $scope.contactQuery.appeal = prefs.appeal;
            if(prefs.appeal[0]){
                jQuery("#leftmenu #filter_appeal").trigger("click");
            }
        }
        if(angular.isDefined(prefs.pledge_frequencies) || angular.isDefined(prefs.pledge_received)){
            $scope.contactQuery.pledge_frequencies = prefs.pledge_frequencies;
            $scope.contactQuery.pledge_received = prefs.pledge_received;
            if(prefs.pledge_frequencies[0] || prefs.pledge_received){
                jQuery("#filter_commitment_details").trigger("click");
            }
        }
        if(angular.isDefined(prefs.city)
          || angular.isDefined(prefs.state)
          || angular.isDefined(prefs.region)
          || angular.isDefined(prefs.metro_area)){
            $scope.contactQuery.city = prefs.city;
            $scope.contactQuery.state = prefs.state;
            $scope.contactQuery.region = prefs.region;
            $scope.contactQuery.metro_area = prefs.metro_area;
            if(prefs.city[0] || prefs.state[0] || prefs.region[0] || prefs.metro_area[0]){
                jQuery("#filter_contact_location").trigger("click");
            }
        }
        if(angular.isDefined(prefs.contact_info_email)
          || angular.isDefined(prefs.contact_info_phone)
          || angular.isDefined(prefs.contact_info_mobile)
          || angular.isDefined(prefs.contact_info_addr)
          || angular.isDefined(prefs.contact_info_facebook)){
            $scope.contactQuery.contact_info_email = prefs.contact_info_email;
            $scope.contactQuery.contact_info_phone = prefs.contact_info_phone;
            $scope.contactQuery.contact_info_mobile = prefs.contact_info_mobile;
            $scope.contactQuery.contact_info_addr = prefs.contact_info_addr;
            $scope.contactQuery.contact_info_facebook = prefs.contact_info_facebook;
            if(prefs.contact_info_email || prefs.contact_info_phone || prefs.contact_info_mobile
               || prefs.contact_info_addr || prefs.contact_info_facebook)
                jQuery("#filter_contact_info").trigger("click");
        }
    });

    $scope.tagIsActive = function(tag){
        return _.contains($scope.contactQuery.tags, tag);
    };

    $scope.tagClick = function(tag, $event){
        if($event && $event.target.attributes['data-method'])
            return;
        if($scope.tagIsActive(tag)){
            _.remove($scope.contactQuery.tags, function(i) { return i === tag; });
            if($scope.contactQuery.tags.length === 0){
                $scope.contactQuery.tags.push('');
            }
        }else{
            _.remove($scope.contactQuery.tags, function(i) { return i === ''; });
            $scope.contactQuery.tags.push(tag);
        }
    };

    $scope.$watch('contactQuery', function (q, oldq) {
        if(!q.viewPrefsLoaded){
            return;
        }
        if(q.page === oldq.page){
            $scope.page.current = 1;
            if(q.page !== 1){
                return;
            }
        }

        refreshContacts();
    }, true);

    $scope.isEmptyFilter = function() {
        return isEmptyFilter($scope.contactQuery);
    }

    var refreshContacts = function () {
      var q = $scope.contactQuery;

      $scope.contactsLoading = true;

      var statusApiArray = q.status;
      if (_.contains(q.status, 'active')) {
        statusApiArray = _.uniq(_.union(statusApiArray, railsConstants.contact.ACTIVE_STATUSES));
      }
      if (_.contains(q.status, 'hidden')) {
        statusApiArray = _.uniq(_.union(statusApiArray, railsConstants.contact.INACTIVE_STATUSES));
      }

        var requestUrl;
        if(q.insightFilter){
            requestUrl = 'contacts?account_list_id=' + (window.current_account_list_id || '') +
                '&per_page=' + q.limit +
                '&page=' + q.page +
                '&filters[ids]=' + q.insightFilter.join();
        } else {
            requestUrl = 'contacts?account_list_id=' + (window.current_account_list_id || '') +
                '&per_page=' + q.limit +
                '&page=' + q.page +
                '&filters[name]=' + encodeURIComponent(q.name) +
                '&filters[contact_type]=' + encodeURIComponent(q.type) +
                '&filters[address_historic]=' + encodeURIComponent(!q.activeAddresses) +
                '&filters[city][]=' + encodeURLarray(q.city).join('&filters[city][]=') +
                '&filters[state][]=' + encodeURLarray(q.state).join('&filters[state][]=') +
                '&filters[region][]=' + encodeURLarray(q.region).join('&filters[region][]=') +
                '&filters[metro_area][]=' + encodeURLarray(q.metro_area).join('&filters[metro_area][]=') +
                '&filters[newsletter]=' + encodeURIComponent(q.newsletter) +
                '&filters[tags][]=' + encodeURLarray(q.tags).join('&filters[tags][]=') +
                '&filters[status][]=' + encodeURLarray(statusApiArray).join('&filters[status][]=') +
                '&filters[likely][]=' + encodeURLarray(q.likely).join('&filters[likely][]=') +
                '&filters[church][]=' + encodeURLarray(q.church).join('&filters[church][]=') +
                '&filters[referrer][]=' + encodeURLarray(q.referrer).join('&filters[referrer][]=') +
                '&filters[timezone][]=' + encodeURLarray(q.timezone).join('&filters[timezone][]=') +
                '&filters[relatedTaskAction][]=' + encodeURLarray(q.relatedTaskAction).join('&filters[relatedTaskAction][]=') +
                '&filters[appeal][]=' + encodeURLarray(q.appeal).join('&filters[appeal][]=') +
                '&filters[wildcard_search]=' + encodeURIComponent(q.wildcardSearch) +
                '&filters[pledge_received]=' + encodeURIComponent(q.pledge_received) +
                '&filters[pledge_frequencies][]=' + encodeURLarray(q.pledge_frequencies).join('&filters[pledge_frequencies][]=') +
                '&filters[contact_info_email]=' + encodeURIComponent(q.contact_info_email) +
                '&filters[contact_info_phone]=' + encodeURIComponent(q.contact_info_phone) +
                '&filters[contact_info_mobile]=' + encodeURIComponent(q.contact_info_mobile) +
                '&filters[contact_info_addr]=' + encodeURIComponent(q.contact_info_addr) +
                '&filters[contact_info_facebook]=' + encodeURIComponent(q.contact_info_facebook) ;
        }

      api.call('get', requestUrl, {}, function (data) {
        angular.forEach(data.contacts, function (contact) {
          var people = _.filter(data.people, function (i) {
            return _.contains(contact.person_ids, i.id);
          });
          var flattenedEmailAddresses = _.flatten(_.pluck(people, 'email_address_ids'));
          var flattenedFacebookAccounts = _.flatten(_.pluck(people, 'facebook_account_ids'));
          contact.pledge_received = contact.pledge_received == 'true'

          contactCache.update(contact.id, {
            addresses: _.filter(data.addresses, function (addr) {
              return _.contains(contact.address_ids, addr.id);
            }),
            people: people,
            email_addresses: _.filter(data.email_addresses, function (email) {
              return _.contains(flattenedEmailAddresses, email.id);
            }),
            contact: _.find(data.contacts, { 'id': contact.id }),
            phone_numbers: data.phone_numbers,
            facebook_accounts: _.filter(data.facebook_accounts, function (fb) {
              return _.contains(flattenedFacebookAccounts, fb.id);
            })
          });
        });
        $scope.contacts = data.contacts;

        if(!_.isNull(document.getElementById('contacts-scrollable'))) {
            document.getElementById('contacts-scrollable').scrollTop = 0;
        }

        $scope.totalContacts = data.meta.total;
        $scope.page.total = data.meta.total_pages;
        $scope.page.from = data.meta.from;
        $scope.page.to = data.meta.to;

        $scope.contactsLoading = false;

        //Save View Prefs
        var prefsToSave = {
          tags: q.tags.join(),
          name: q.name,
          type: q.type,
          city: q.city,
          state: q.state,
          region: q.region,
          metro_area: q.metro_area,
          newsletter: q.newsletter,
          status: statusApiArray,
          likely: q.likely,
          church: q.church,
          referrer: q.referrer,
          timezone: q.timezone,
          relatedTaskAction: q.relatedTaskAction,
          appeal: q.appeal,
          pledge_frequencies: q.pledge_frequencies,
          pledge_received: q.pledge_received,
          contact_info_email: q.contact_info_email,
          contact_info_phone: q.contact_info_phone,
          contact_info_mobile: q.contact_info_mobile,
          contact_info_addr: q.contact_info_addr,
          contact_info_facebook: q.contact_info_facebook
        };
        if (!isEmptyFilter(prefsToSave)) {
          viewPrefs['user']['preferences']['contacts_filter'][window.current_account_list_id] = prefsToSave;
        } else {
          viewPrefs['user']['preferences']['contacts_filter'][window.current_account_list_id] = null;
        }
        api.call('put', 'users/me', viewPrefs);
      }, null, true);
    };

    $scope.$watch('page', function (p) {
        $scope.contactQuery.page = p.current;
    }, true);

    var isEmptyFilter = function (q) {
      if (!_.isEmpty(_.without(q.tags, '')) || !_.isEmpty(q.name) || !_.isEmpty(q.type) ||
          !_.isEmpty(_.without(q.city, '')) || !_.isEmpty(_.without(q.state, '')) ||
          !_.isEmpty(_.without(q.region, '')) ||
          !_.isEmpty(_.without(q.metro_area, '')) || !_.isEmpty(q.newsletter) ||
          !_.isEmpty(_.without(q.likely, '')) ||
          !_.isEmpty(_.without(q.church, '')) ||
          !_.isEmpty(_.without(q.referrer, '')) ||
          !_.isEmpty(_.without(q.relatedTaskAction, '')) ||
          !_.isEmpty(_.without(q.timezone, '')) ||
          !_.isEmpty(_.without(q.appeal, '')) ||
          !_.isEmpty(_.without(q.pledge_frequencies, '')) ||
          !_.isEmpty(_.without(q.pledge_received, '')) ||
          !_.isEmpty(q.contact_info_email) ||
          !_.isEmpty(q.contact_info_phone) ||
          !_.isEmpty(q.contact_info_mobile) ||
          !_.isEmpty(q.contact_info_addr) ||
          !_.isEmpty(q.contact_info_facebook))
      {
        return false;
      }

      if (!_.contains(q.status, 'active') || !_.contains(q.status, 'null')) {
        return false;
      }

      return true;
    };

    var generateContactMarker = function(contact) {
      var cc = contactCache.getFromCache(contact.id);
      var marker;
      if(cc && cc.addresses && cc.addresses.length > 0) {
        var geo = cc.addresses[0].geo;
        if(geo) {
          marker = {
            'lat': geo.split(',')[0],
            'lng': geo.split(',')[1],
            'infowindow': '<a href="/contacts/'+contact.id+'">' + contact.name + '</a>',
            'picture': {
              'url': markerURL(contact.status),
              'width':  20,
              'height': 36
            }
          }
        }
      }
      return marker;
    }
    var markerURL = function(status) {
      var base = 'https://chart.googleapis.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|'
      switch(status) {
        case '':
        case 'Never Contacted':
          return base + 'dcdcdc';
        case 'Ask in Future':
          return base + 'F04141';
        case 'Contact for Appointment':
          return base + 'F0D541';
        case 'Appointment Scheduled':
          return base + '54DB1A';
        case 'Call for Decision':
          return base + '41F0A1';
        case 'Partner - Financial':
          return base + '41AAF0';
        case 'Partner - Special':
          return base + '6C41F0';
        case 'Partner - Pray':
          return base + 'F26FE5';
        case 'Cultivate Relationship':
          return base + 'cf641e';
      }
      return base + '757575'
    }

    $scope.mapContacts = function() {
      var newMarkers = [];
      var contactsCounts = {
        noAddress: 0
      }
      angular.forEach($scope.contacts, function(contact) {
        var marker = generateContactMarker(contact);
        if(marker)
          newMarkers.push(marker);
        else
          contactsCounts.noAddress++;
      })
      $('#contacts_map_modal').dialog({ width: 700, height: 615 })
      var addMarkers = function(){
        $scope.mapHandler.removeMarkers($scope.mapMarkers)
        $scope.mapMarkers = $scope.mapHandler.addMarkers(newMarkers);
        $scope.mapHandler.bounds.extendWith($scope.mapMarkers);
        $scope.mapHandler.fitMapToBounds();
      }
      $scope.singleMap(addMarkers)
      $('.contacts_counts').text(contactsCounts.noAddress + '/' + $scope.contacts.length)
    };
    $scope.mapMarkers = [];

    $scope.singleMap = function(methodToExec) {
      if(methodToExec === undefined || typeof(methodToExec) != "function")
        methodToExec = $.noop
      var mapOptions = { streetViewControl: false };
      if($scope.mapHandler === undefined) {
        $scope.mapHandler = Gmaps.build('Google');
        $scope.mapHandler.buildMap(
          {
            provider: mapOptions,
            internal: {id: 'contacts-map'}
          },
          methodToExec
        );
      }
      else
        methodToExec()
    };

    $scope.runInsight = function(insight){
      if(insight === 'recommendations'){
        api.call('get', 'insights', {}, function (data) {
          $scope.contactQuery.insightFilter = data.insights;
        }, function(){
          alert('An error has occurred while retrieving insight contacts');
        });
      }
    };

    $scope.clearInsightFilter = function(){
      delete $scope.contactQuery.insightFilter;
    };

    $scope.insightFilterIsActive = function(){
      return angular.isDefined($scope.contactQuery.insightFilter);
    };
});


function encodeURLarray(array){
    var encoded = [];
    angular.forEach(array, function(value, key){
        encoded.push(encodeURIComponent(value));
    });
    return encoded;
}
