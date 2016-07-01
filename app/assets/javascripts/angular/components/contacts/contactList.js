(function(){
    angular
        .module('mpdxApp')
        .component('contactList', {
            controller: contactListController,
            templateUrl: 'inline/contact_list.html' //declared inline at app/views/contacts/index.html.erb
        });

    contactListController.$inject = ['$scope', 'api', 'contactCache', 'urlParameter', '$log', 'state', 'selectionStore', 'railsConstants'];

    function contactListController($scope, api, contactCache, urlParameter, $log, state, selectionStore, railsConstants) {
        var vm = this;

        vm.contactsLoading = true;
        vm.totalContacts = 0;
        vm.viewPrefsLoaded = false;
        vm.selectedContacts = [];
        vm.mapMarkers = [];
        vm.showAllFilterTags = false;
        vm.contactQuery = {};

        // A status of 'null' corresponds with '-- NONE --' in the html select
        var defaultFilters = {
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
            status: _.union(['active', 'null'], railsConstants.contact.ACTIVE_STATUSES),
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
            page: 1,
            limit: 25,
            wildcardSearch: null
        };

        vm.pageMeta = {
            total: 1,
            from: 0,
            to: 0
        };

        vm.isEmptyFilter = isEmptyFilter;
        vm.resetFilters = resetFilters;
        vm.tagIsActive = tagIsActive;
        vm.tagClick = tagClick;
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

        vm._refreshContacts = refreshContacts;
        vm._buildContactFilterUrl = buildContactFilterUrl;
        vm._handleContactQueryChanges = handleContactQueryChanges;
        vm._loadViewPreferences = loadViewPreferences;
        vm._diffContactFilters = diffContactFilters;
        vm._initializeFilters = initializeFilters;
        vm._getChangedFilterPanelGroups = getChangedFilterPanelGroups;

        vm.$onInit = activate;

        function activate() {
            initializeFilters();
            refreshContacts();

            loadViewPreferences();
            loadSelectedContacts();

            $scope.$watch('$ctrl.contactQuery', function (q, oldq) {
                if(!vm.viewPrefsLoaded){
                    return;
                }

                handleContactQueryChanges(oldq);
                refreshContacts();
            }, true);
        }

        function refreshContacts() {
            vm.contactsLoading = true;

            api.call('get', buildContactFilterUrl(), {}, function (data) {
                angular.forEach(data.contacts, function (contact) {
                    var people = _.filter(data.people, function (i) {
                        return _.includes(contact.person_ids, i.id);
                    });
                    var flattenedEmailAddresses = _.flatMap(people, 'email_address_ids');
                    var flattenedFacebookAccounts = _.flatMap(people, 'facebook_account_ids');
                    contact.pledge_received = contact.pledge_received == 'true';

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

                if(data.meta) {
                    vm.totalContacts = data.meta.total;
                    vm.pageMeta.total = data.meta.total_pages;
                    vm.pageMeta.from = data.meta.from;
                    vm.pageMeta.to = data.meta.to;
                }

                //Handles case where limit is increased (or another filter change) which could result in the current page being out of range
                if(vm.contactQuery.page > vm.pageMeta.total){
                    vm.contactQuery.page = vm.pageMeta.total;
                }

                vm.contactsLoading = false;

                saveViewPreferences();
            }, null, true);
        }

        function buildContactFilterUrl(){
            if(vm.contactQuery.insightFilter){
                return 'contacts?account_list_id=' + (state.current_account_list_id || '') +
                    '&per_page=' + vm.contactQuery.limit +
                    '&page=' + vm.contactQuery.page +
                    '&filters[ids]=' + vm.contactQuery.insightFilter.join();
            } else {
                var keysToRename = {
                    limit: 'per_page',
                    type: 'contact_type',
                    activeAddresses: 'address_historic',
                    currency: 'pledge_currency',
                    wildcardSearch: 'wildcard_search'
                };

                var excludeFromFilterObject = ['page', 'per_page'];

                var filtersQueryString = _(vm.contactQuery)
                    .pick(diffContactFilters(defaultFilters, vm.contactQuery)) // Only send non-default filters
                    .thru(function(filters){
                        // A false activeAddresses value should result in a true address_historic value
                        if(filters.activeAddresses === false){
                            filters.activeAddresses = true;
                        }
                        return filters;
                    })
                    .mapKeys(function(filterValue, filterName){
                        // Rename keys that are different on the server
                        var keyName = keysToRename[filterName] || filterName;

                        // Create Query Param key
                        if(_.includes(excludeFromFilterObject, keyName)){
                            return keyName;
                        }else{
                            return 'filters[' + keyName + ']' + (_.isArray(filterValue) ? '[]' : '');
                        }
                    })
                    .reduce(function(queryString, filterValues, filterKey){
                        // Force filterValues to be an array
                        filterValues = _.concat(filterValues);
                        // Reduce all values for this key into query params with the same key
                        return queryString + _.reduce(filterValues, function(acc, filterValue){
                                return acc + '&' + filterKey + '=' + encodeURIComponent(filterValue);
                            }, '');
                    }, '');

                return 'contacts?account_list_id=' + (state.current_account_list_id || '') + filtersQueryString;
            }
        }

        function handleContactQueryChanges(oldContactQuery){
            // Include all active statuses with active
            if(_.includes(vm.contactQuery.status, 'active')){
                vm.contactQuery.status = _.union(vm.contactQuery.status, railsConstants.contact.ACTIVE_STATUSES)
            }

            // Include all inactive statuses with hidden
            if(_.includes(vm.contactQuery.status, 'hidden')){
                vm.contactQuery.status = _.union(vm.contactQuery.status, railsConstants.contact.INACTIVE_STATUSES)
            }

            // If the user changes the filters (by anything other than
            // page or limit), then clear their selection as their
            // selected contacts might not be anywhere in the list anymore.
            if (vm.viewPrefsLoaded && !_.isEmpty(diffContactFilters(oldContactQuery, vm.contactQuery, ['limit', 'page']))) {
                vm.clearSelectedContacts();
                vm.contactQuery.page = 1;
            }
        }

        function loadViewPreferences() {
            api.call('get', 'users/me', {}, function (viewPrefs) {
                vm.viewPrefsLoaded = true;

                if (!_.has(viewPrefs, 'user.preferences.contacts_filter[' + state.current_account_list_id + ']')) {
                    return;
                }

                // Limit currently isn't stored with the rest of the view preferences and is loaded with preload-state
                vm.contactQuery = _.defaults(_.pick(vm.contactQuery, 'wildcardSearch', 'limit'), viewPrefs.user.preferences.contacts_filter[state.current_account_list_id], defaultFilters);

                if (_.isString(vm.contactQuery.tags)) {
                    vm.contactQuery.tags = vm.contactQuery.tags.split(',');
                }

                openFilterPanels();
            });
        }

        function saveViewPreferences(){
            var viewPrefs = {
                user: {
                    preferences: {
                        contacts_filter: {}
                    }
                },
                account_list_id: state.current_account_list_id
            };
            viewPrefs.user.preferences.contacts_filter[state.current_account_list_id] = _.omit(vm.contactQuery, ['wildcardSearch']);
            viewPrefs.user.preferences.contacts_filter[state.current_account_list_id].tags = vm.contactQuery.tags.join();

            api.call('put', 'users/me', viewPrefs);
        }

        function openFilterPanels(){
            _.forEach(getChangedFilterPanelGroups(), function(id){
                angular.element('#leftmenu #filter_' + id).trigger("click");
            });
        }

        function getChangedFilterPanelGroups(){
            var changedContactFilters = diffContactFilters(defaultFilters, vm.contactQuery, ['limit', 'page']);

            var filterDisplayGroups = {
                single: ['type', 'newsletter', 'status', 'likely', 'church', 'referrer', 'timezone', 'locale', 'relatedTaskAction', 'appeal'],
                commitment_details: ['pledge_frequencies', 'pledge_received'],
                contact_location: ['city', 'state', 'region', 'metro_area', 'country'],
                contact_info: ['contact_info_email', 'contact_info_phone', 'contact_info_mobile', 'contact_info_addr', 'contact_info_facebook']
            };

            return _.reduce(filterDisplayGroups, function(filterIds, filtersInGroup, groupName) {
                if(groupName === 'single'){
                    return _.union(filterIds, _.intersection(filtersInGroup, changedContactFilters));
                }
                if(!_.isEmpty(_.intersection(filtersInGroup, changedContactFilters))) {
                    return filterIds.concat(groupName);
                }
                return filterIds;
            }, []);
        }

        function diffContactFilters(left, right, ignore){
            var valueDifferences =  _.reduce(left, function(result, value, key) {
                return _.isEqual(value, right[key]) ?
                    result : result.concat(key);
            }, []);
            var missingKeys = _.xor(_.keys(left), _.keys(right));
            var allChanges = _.union(valueDifferences, missingKeys);
            return _.difference(allChanges, ignore);
        }

        function isEmptyFilter(q) {
            q = q || vm.contactQuery;
            return _.isEmpty(diffContactFilters(defaultFilters, q, ['limit', 'page']));
        }

        function initializeFilters(){
            // Set default filters, loading limit from state and wildcardSearch from url param
            _.assign(vm.contactQuery, defaultFilters, {
                limit: parseInt(state.contact_limit || defaultFilters.limit),
                wildcardSearch: urlParameter.get('q') || null
            });

            // Clear the selected contacts if the user did a search since they
            // would be expecting to just be selecting on the resulting
            // contacts.
            if (vm.contactQuery.wildcardSearch !== null) {
                vm.clearSelectedContacts();
            }
        }

        function resetFilters(){
            _.assign(vm.contactQuery, _.omit(defaultFilters, 'limit'));
            clearSelectedContacts();
            angular.element('#globalContactSearch').value = '';
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
