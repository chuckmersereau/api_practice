(function(){
    angular
        .module('mpdxApp')
        .component('contactList', {
            controller: contactListController,
            templateUrl: 'inline/contact_list.html' //declared inline at app/views/contacts/index.html.erb
        });

    contactListController.$inject = ['$scope', 'api', 'contactCache', 'urlParameter', '$log', 'state', 'selectionStore'];

    function contactListController($scope, api, contactCache, urlParameter, $log, state, selectionStore) {
        var vm = this;

        var viewPrefs;

        vm.contactsLoading = true;
        vm.totalContacts = 0;

        vm.contactQuery = {
            limit: 25,
            page: 1,
            ids: '',
            tags: [''],
            name: '',
            type: '',
            activeAddresses: true,
            city: [''],
            state: [''],
            region: [''],
            metro_area: [''],
            country: [''],
            newsletter: '',
            status: ['active', 'null'],
            likely: [''],
            church: [''],
            referrer: [''],
            timezone: [''],
            currency: [''],
            locale: [''],
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

        vm.page = {
            current: 1,
            total: 1,
            from: 0,
            to: 0
        };

        vm.selectedContacts = [];
        vm.mapMarkers = [];
        vm.showAllFilterTags = false;

        vm.resetFilters = resetFilters;
        vm.tagIsActive = tagIsActive;
        vm.tagClick = tagClick;
        vm.isEmptyFilter = isEmptyFilter;
        vm.mapContacts = mapContacts;
        vm.singleMap = singleMap;
        vm.runInsight = runInsight;
        vm.clearInsightFilter = clearInsightFilter;
        vm.insightFilterIsActive = insightFilterIsActive;
        vm.clearSelectedContacts = clearSelectedContacts;
        vm.toggleSelectedContacts = toggleSelectedContacts;
        vm.toggleSelectedContactsAllOnPage = toggleSelectedContactsAllOnPage;
        vm.anyContactIdsSelected = anyContactIdsSelected;
        vm.anyContactsOnPageSelected = anyContactsOnPageSelected;
        vm.noSelectedContacts = noSelectedContacts;

        activate();

        function isSameExceptPage(contactQuery1, contactQuery2) {
            for (var key in contactQuery1) {
                if (key != 'page' && !_.isEqual(contactQuery1[key], contactQuery2[key])) {
                    return false;
                }
            }
            return true;
        }

        function activate() {
            // Clear the selected contacts if the user did a search since they
            // would be expecting to just be selecting on the resulting
            // contacts.
            if (vm.contactQuery.wildcardSearch !== null) {
                clearSelectedContacts();
            }

            loadViewPreferences();
            loadSelectedContacts();

            $scope.$watch('$ctrl.contactQuery', function (q, oldq) {
                if(!q.viewPrefsLoaded){
                    return;
                }
                if(q.page === oldq.page){
                    vm.page.current = 1;
                    if(q.page !== 1){
                        return;
                    }
                }

                // If the user changes the filters (by anything other than
                // moving to another page), then clear their selection as their
                // selected contacts might not be anywhere in the list anymore.
                if (oldq.viewPrefsLoaded && !isSameExceptPage(q, oldq)) {
                    clearSelectedContacts();
                }

                refreshContacts();
            }, true);

            $scope.$watch('$ctrl.page', function (p) {
                vm.contactQuery.page = p.current;
            }, true);
        }

        function loadViewPreferences() {
            //view preferences
            api.call('get', 'users/me', {}, function (data) {
                viewPrefs = data;
                vm.contactQuery.viewPrefsLoaded = true;

                if (angular.isUndefined(viewPrefs.user.preferences.contacts_filter)) {
                    var prefs = null;
                    viewPrefs.user.preferences.contacts_filter = {};
                } else {
                    var prefs = viewPrefs.user.preferences.contacts_filter[state.current_account_list_id];
                }

                if (!_.isNull(vm.contactQuery.wildcardSearch)) {
                    var prefs = null;
                    viewPrefs.user.preferences.contacts_filter = {};
                }

                if (_.isNull(prefs)) {
                    return;
                }
                if (angular.isDefined(prefs.ids)) {
                    vm.contactQuery.ids = prefs.ids;
                }
                if (angular.isDefined(prefs.tags)) {
                    vm.contactQuery.tags = prefs.tags.split(',');
                }
                if (angular.isDefined(prefs.type)) {
                    vm.contactQuery.type = prefs.type;
                    if (prefs.type) {
                        jQuery("#leftmenu #filter_type").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.newsletter)) {
                    vm.contactQuery.newsletter = prefs.newsletter;
                    if (prefs.newsletter) {
                        jQuery("#leftmenu #filter_newsletter").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.status)) {
                    vm.contactQuery.status = prefs.status;
                    if (prefs.status[0] !== 'active') {
                        jQuery("#leftmenu #filter_status").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.likely)) {
                    vm.contactQuery.likely = prefs.likely;
                    if (prefs.likely[0]) {
                        jQuery("#leftmenu #filter_likely").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.church)) {
                    vm.contactQuery.church = prefs.church;
                    if (prefs.church[0]) {
                        jQuery("#leftmenu #filter_church").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.referrer)) {
                    vm.contactQuery.referrer = prefs.referrer;
                    if (prefs.referrer[0]) {
                        jQuery("#leftmenu #filter_referrer").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.timezone)) {
                    vm.contactQuery.timezone = prefs.timezone;
                    if (prefs.timezone[0]) {
                        jQuery("#leftmenu #filter_timezone").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.currency)) {
                    vm.contactQuery.currency = prefs.currency;
                    if (prefs.currency[0]) {
                        jQuery("#leftmenu #filter_currency").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.locale)) {
                    vm.contactQuery.locale = prefs.locale;
                    if (prefs.locale[0]) {
                        jQuery("#leftmenu #contact_locale").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.relatedTaskAction)) {
                    vm.contactQuery.relatedTaskAction = prefs.relatedTaskAction;
                    if (prefs.relatedTaskAction[0]) {
                        jQuery("#leftmenu #filter_relatedTaskAction").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.appeal)) {
                    vm.contactQuery.appeal = prefs.appeal;
                    if (prefs.appeal[0]) {
                        jQuery("#leftmenu #filter_appeal").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.pledge_frequencies) || angular.isDefined(prefs.pledge_received)) {
                    vm.contactQuery.pledge_frequencies = prefs.pledge_frequencies || [];
                    vm.contactQuery.pledge_received = prefs.pledge_received || '';
                    if (prefs.pledge_frequencies[0] || prefs.pledge_received) {
                        jQuery("#filter_commitment_details").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.city)
                    || angular.isDefined(prefs.state)
                    || angular.isDefined(prefs.region)
                    || angular.isDefined(prefs.metro_area)
                    || angular.isDefined(prefs.country)) {
                    vm.contactQuery.city = prefs.city || [];
                    vm.contactQuery.state = prefs.state || [];
                    vm.contactQuery.region = prefs.region || [];
                    vm.contactQuery.metro_area = prefs.metro_area || [];
                    vm.contactQuery.country = prefs.country || [];
                    if ((prefs.city && prefs.city[0]) || (prefs.state && prefs.state[0]) ||
                        (prefs.region && prefs.region[0]) || (prefs.metro_area && prefs.metro_area[0]) ||
                        (prefs.country && prefs.country[0])) {
                        jQuery("#filter_contact_location").trigger("click");
                    }
                }
                if (angular.isDefined(prefs.contact_info_email)
                    || angular.isDefined(prefs.contact_info_phone)
                    || angular.isDefined(prefs.contact_info_mobile)
                    || angular.isDefined(prefs.contact_info_addr)
                    || angular.isDefined(prefs.contact_info_facebook)) {
                    vm.contactQuery.contact_info_email = prefs.contact_info_email;
                    vm.contactQuery.contact_info_phone = prefs.contact_info_phone;
                    vm.contactQuery.contact_info_mobile = prefs.contact_info_mobile;
                    vm.contactQuery.contact_info_addr = prefs.contact_info_addr;
                    vm.contactQuery.contact_info_facebook = prefs.contact_info_facebook;
                    if (prefs.contact_info_email || prefs.contact_info_phone || prefs.contact_info_mobile
                        || prefs.contact_info_addr || prefs.contact_info_facebook)
                        jQuery("#filter_contact_info").trigger("click");
                }

                if (angular.isDefined(prefs.page)) {
                    vm.page.current = prefs.page;
                    vm.contactQuery.page = prefs.page;
                }
            });
        }

        function resetFilters(){
            vm.contactQuery.tags = [''];
            vm.contactQuery.ids = '';
            vm.contactQuery.name = '';
            vm.contactQuery.type = '';
            vm.contactQuery.activeAddresses = true;
            vm.contactQuery.city = [''];
            vm.contactQuery.state = [''];
            vm.contactQuery.region = [''];
            vm.contactQuery.metro_area = [''];
            vm.contactQuery.country = [''];
            vm.contactQuery.newsletter = '';
            vm.contactQuery.status = ['active', 'null'];
            vm.contactQuery.likely = [''];
            vm.contactQuery.church = [''];
            vm.contactQuery.referrer = [''];
            vm.contactQuery.timezone = [''];
            vm.contactQuery.currency = [''];
            vm.contactQuery.locale = [''];
            vm.contactQuery.relatedTaskAction = [''];
            vm.contactQuery.appeal = [''];
            vm.contactQuery.pledge_frequencies = [''];
            vm.contactQuery.pledge_received = '';
            vm.contactQuery.wildcardSearch = null;
            vm.contactQuery.contact_info_email = '';
            vm.contactQuery.contact_info_phone = '';
            vm.contactQuery.contact_info_mobile = '';
            vm.contactQuery.contact_info_addr = '';
            vm.contactQuery.contact_info_facebook = '';
            clearSelectedContacts();
            if(!_.isNull(document.getElementById('globalContactSearch'))) {
                document.getElementById('globalContactSearch').value = '';
            }
        }

        function tagIsActive(tag){
            return _.includes(vm.contactQuery.tags, tag);
        }

        function tagClick(tag, $event){
            if($event && $event.target.attributes['data-method'])
                return;
            if(vm.tagIsActive(tag)){
                _.remove(vm.contactQuery.tags, function(i) { return i === tag; });
                if(vm.contactQuery.tags.length === 0){
                    vm.contactQuery.tags.push('');
                }
            }else{
                _.remove(vm.contactQuery.tags, function(i) { return i === ''; });
                vm.contactQuery.tags.push(tag);
            }
        }

        function isEmptyFilter(q) {
            q = q || vm.contactQuery;
            if (!isEmptyTagsFilter(q.tags) || !_.isEmpty(q.name) || !_.isEmpty(q.type) ||
                !_.isEmpty(_.without(q.city, '')) || !_.isEmpty(_.without(q.state, '')) ||
                !_.isEmpty(_.without(q.region, '')) || !_.isEmpty(q.ids) ||
                !_.isEmpty(_.without(q.metro_area, '')) ||
                !_.isEmpty(_.without(q.country, '')) || !_.isEmpty(q.newsletter) ||
                !_.isEmpty(_.without(q.likely, '')) ||
                !_.isEmpty(_.without(q.church, '')) ||
                !_.isEmpty(_.without(q.referrer, '')) ||
                !_.isEmpty(_.without(q.relatedTaskAction, '')) ||
                !_.isEmpty(_.without(q.timezone, '')) ||
                !_.isEmpty(_.without(q.currency, '')) ||
                !_.isEmpty(_.without(q.locale, '')) ||
                !_.isEmpty(_.without(q.appeal, '')) ||
                !_.isEmpty(_.without(q.pledge_frequencies, '')) ||
                !_.isEmpty(_.without(q.pledge_received, '')) ||
                !_.isEmpty(q.contact_info_email) ||
                !_.isEmpty(q.contact_info_phone) ||
                !_.isEmpty(q.contact_info_mobile) ||
                !_.isEmpty(q.contact_info_addr) ||
                !_.isEmpty(q.contact_info_facebook) ||
                q.page !== 1)
            {
                return false;
            }

            // This is a temporary fix to make the karma tests past. What we really
            // need to remove this is for the karma tests to run in the environment of
            // the correctly evaluated sprokets pipeline (which would expand
            // railsConstants.js.erb), but currently it does not, which makes
            // railsConstants undefined.
            if (!angular.isDefined(window.railsConstants)) {
                window.railsConstants = {
                    contact: {
                        INACTIVE_STATUSES: []
                    }
                };
            }

            inactiveQueryStatuses =
                _.intersection(q.status, window.railsConstants.contact.INACTIVE_STATUSES);

            if (!_.includes(q.status, 'active') || !_.includes(q.status, 'null') ||
                !_.isEmpty(inactiveQueryStatuses) || _.includes(q.status, 'hidden')) {
                return false;
            }

            return true;
        }

        // The tags filter is serialized in some places as a comma delimited
        // string and sometimes as an array of tags. This method will check the
        // tags for emptiness based on its representation.
        function isEmptyTagsFilter(tags) {
            if (Array.isArray(tags)) {
                return _.isEmpty(_.without(tags, ''));
            } else {
                return _.isEmpty(tags);
            }
        }

        function refreshContacts() {
            var q = vm.contactQuery;

            vm.contactsLoading = true;

            var statusApiArray = q.status;
            if (_.includes(q.status, 'active')) {
                statusApiArray = _.uniq(_.union(statusApiArray, railsConstants.contact.ACTIVE_STATUSES));
            }
            if (_.includes(q.status, 'hidden')) {
                statusApiArray = _.uniq(_.union(statusApiArray, railsConstants.contact.INACTIVE_STATUSES));
            }

            var requestUrl;
            if(q.insightFilter){
                requestUrl = 'contacts?account_list_id=' + (state.current_account_list_id || '') +
                    '&per_page=' + q.limit +
                    '&page=' + q.page +
                    '&filters[ids]=' + q.insightFilter.join();
            } else {
                requestUrl = 'contacts?account_list_id=' + (state.current_account_list_id || '') +
                    '&per_page=' + q.limit +
                    '&page=' + q.page +
                    '&filters[ids]=' + encodeURIComponent(q.ids) +
                    '&filters[name]=' + encodeURIComponent(q.name) +
                    '&filters[contact_type]=' + encodeURIComponent(q.type) +
                    '&filters[address_historic]=' + encodeURIComponent(!q.activeAddresses) +
                    '&filters[city][]=' + api.encodeURLarray(q.city).join('&filters[city][]=') +
                    '&filters[state][]=' + api.encodeURLarray(q.state).join('&filters[state][]=') +
                    '&filters[region][]=' + api.encodeURLarray(q.region).join('&filters[region][]=') +
                    '&filters[metro_area][]=' + api.encodeURLarray(q.metro_area).join('&filters[metro_area][]=') +
                    '&filters[country][]=' + api.encodeURLarray(q.country).join('&filters[country][]=') +
                    '&filters[newsletter]=' + encodeURIComponent(q.newsletter) +
                    '&filters[tags][]=' + api.encodeURLarray(q.tags).join('&filters[tags][]=') +
                    '&filters[status][]=' + api.encodeURLarray(statusApiArray).join('&filters[status][]=') +
                    '&filters[likely][]=' + api.encodeURLarray(q.likely).join('&filters[likely][]=') +
                    '&filters[church][]=' + api.encodeURLarray(q.church).join('&filters[church][]=') +
                    '&filters[referrer][]=' + api.encodeURLarray(q.referrer).join('&filters[referrer][]=') +
                    '&filters[timezone][]=' + api.encodeURLarray(q.timezone).join('&filters[timezone][]=') +
                    '&filters[pledge_currency][]=' + api.encodeURLarray(q.currency).join('&filters[pledge_currency][]=') +
                    '&filters[locale][]=' + api.encodeURLarray(q.locale).join('&filters[locale][]=') +
                    '&filters[relatedTaskAction][]=' + api.encodeURLarray(q.relatedTaskAction).join('&filters[relatedTaskAction][]=') +
                    '&filters[appeal][]=' + api.encodeURLarray(q.appeal).join('&filters[appeal][]=') +
                    '&filters[wildcard_search]=' + encodeURIComponent(q.wildcardSearch) +
                    '&filters[pledge_received]=' + encodeURIComponent(q.pledge_received) +
                    '&filters[pledge_frequencies][]=' + api.encodeURLarray(q.pledge_frequencies).join('&filters[pledge_frequencies][]=') +
                    '&filters[contact_info_email]=' + encodeURIComponent(q.contact_info_email) +
                    '&filters[contact_info_phone]=' + encodeURIComponent(q.contact_info_phone) +
                    '&filters[contact_info_mobile]=' + encodeURIComponent(q.contact_info_mobile) +
                    '&filters[contact_info_addr]=' + encodeURIComponent(q.contact_info_addr) +
                    '&filters[contact_info_facebook]=' + encodeURIComponent(q.contact_info_facebook) ;
            }

            api.call('get', requestUrl, {}, function (data) {
                angular.forEach(data.contacts, function (contact) {
                    var people = _.filter(data.people, function (i) {
                        return _.includes(contact.person_ids, i.id);
                    });
                    var flattenedEmailAddresses = _.flatMap(people, 'email_address_ids');
                    var flattenedFacebookAccounts = _.flatMap(people, 'facebook_account_ids');
                    contact.pledge_received = contact.pledge_received == 'true'

                    contactCache.update(contact.id, {
                        addresses: _.filter(data.addresses, function (addr) {
                            return _.includes(contact.address_ids, addr.id);
                        }),
                        people: people,
                        email_addresses: _.filter(data.email_addresses, function (email) {
                            return _.includes(flattenedEmailAddresses, email.id);
                        }),
                        contact: _.find(data.contacts, { 'id': contact.id }),
                        phone_numbers: data.phone_numbers,
                        facebook_accounts: _.filter(data.facebook_accounts, function (fb) {
                            return _.includes(flattenedFacebookAccounts, fb.id);
                        })
                    });
                });
                vm.contacts = data.contacts;

                if(!_.isNull(document.getElementById('contacts-scrollable'))) {
                    document.getElementById('contacts-scrollable').scrollTop = 0;
                }

                vm.totalContacts = data.meta.total;
                vm.page.total = data.meta.total_pages;
                vm.page.from = data.meta.from;
                vm.page.to = data.meta.to;

                vm.contactsLoading = false;

                //Save View Prefs
                var prefsToSave = {
                    tags: q.tags.join(),
                    ids: q.ids,
                    name: q.name,
                    type: q.type,
                    city: q.city,
                    state: q.state,
                    region: q.region,
                    metro_area: q.metro_area,
                    country: q.country,
                    newsletter: q.newsletter,
                    status: statusApiArray,
                    likely: q.likely,
                    church: q.church,
                    referrer: q.referrer,
                    timezone: q.timezone,
                    currency: q.currency,
                    locale: q.locale,
                    relatedTaskAction: q.relatedTaskAction,
                    appeal: q.appeal,
                    pledge_frequencies: q.pledge_frequencies,
                    pledge_received: q.pledge_received,
                    contact_info_email: q.contact_info_email,
                    contact_info_phone: q.contact_info_phone,
                    contact_info_mobile: q.contact_info_mobile,
                    contact_info_addr: q.contact_info_addr,
                    contact_info_facebook: q.contact_info_facebook,
                    page: q.page
                };
                if (!isEmptyFilter(prefsToSave)) {
                    viewPrefs['user']['preferences']['contacts_filter'][state.current_account_list_id] = prefsToSave;
                } else {
                    viewPrefs['user']['preferences']['contacts_filter'][state.current_account_list_id] = null;
                }
                api.call('put', 'users/me', viewPrefs);
            }, null, true);
        }

        function generateContactMarker(contact) {
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

        function markerURL(status) {
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

        function mapContacts() {
            var newMarkers = [];
            var contactsCounts = {
                noAddress: 0
            };
            angular.forEach(vm.contacts, function(contact) {
                var marker = generateContactMarker(contact);
                if(marker) {
                    newMarkers.push(marker);
                } else {
                    contactsCounts.noAddress++;
                }
            });
            $('#contacts_map_modal').dialog({ width: 750, height: 615 });
            var addMarkers = function(){
                vm.mapHandler.removeMarkers(vm.mapMarkers);
                vm.mapMarkers = vm.mapHandler.addMarkers(newMarkers);
                vm.mapHandler.bounds.extendWith(vm.mapMarkers);
                vm.mapHandler.fitMapToBounds();
            };
            vm.singleMap(addMarkers);
            $('.contacts_counts').text(contactsCounts.noAddress + '/' + vm.contacts.length);
        }

        function singleMap(methodToExec) {
            if(methodToExec === undefined || typeof(methodToExec) != "function") {
                methodToExec = $.noop;
            }
            var mapOptions = { streetViewControl: false };
            if(vm.mapHandler === undefined) {
                vm.mapHandler = Gmaps.build('Google');
                vm.mapHandler.buildMap(
                    {
                        provider: mapOptions,
                        internal: {id: 'contacts-map'}
                    },
                    methodToExec
                );
            } else {
                methodToExec();
            }
        }

        function runInsight(insight){
            if(insight === 'recommendations'){
                api.call('get', 'insights', {}, function (data) {
                    vm.contactQuery.insightFilter = data.insights;
                }, function(){
                    alert('An error has occurred while retrieving insight contacts');
                });
            }
        }

        function clearInsightFilter(){
            delete vm.contactQuery.insightFilter;
        }

        function insightFilterIsActive(){
            return angular.isDefined(vm.contactQuery.insightFilter);
        }

        function loadSelectedContacts(){
            selectionStore.loadSelectedContacts().then(function(selectedContacts){
                    vm.selectedContacts = selectedContacts;
                },
                function(){
                    $log.error('Failed to load selected contacts');
                });
        }

        function saveSelectedContacts(){
            selectionStore.saveSelectedContacts(vm.selectedContacts)
        }

        function clearSelectedContacts(){
            vm.selectedContacts = [];
            saveSelectedContacts();
        }

        function toggleSelectedContactsAllOnPage(){
            toggleSelectedContacts(allContactIdsOnPage());
        }

        function toggleSelectedContacts(ids){
            if(!_.isArray(ids)){
                ids = [ids];
            }
            if(anyContactIdsSelected(ids)){
                vm.selectedContacts = _.difference(vm.selectedContacts, ids);
            }else {
                vm.selectedContacts = _.union(vm.selectedContacts, ids);
            }
            saveSelectedContacts();
        }

        function anyContactsOnPageSelected(){
            return anyContactIdsSelected(allContactIdsOnPage());
        }

        function anyContactIdsSelected(ids){
            if(!_.isArray(ids)){
                ids = [ids];
            }
            return !_.isEmpty(vm.selectedContacts) && !_.isEmpty(ids) && _(ids).difference(vm.selectedContacts).isEmpty();
        }

        function noSelectedContacts(){
            return _.isEmpty(vm.selectedContacts);
        }

        function allContactIdsOnPage(){
            return _.map(vm.contacts, function(contact){
                return contact.id;
            });
        }
    }
})();
