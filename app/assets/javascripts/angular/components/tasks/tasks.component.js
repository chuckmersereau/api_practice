(function() {
    angular
        .module('mpdxApp')
        .component('tasks', {
            controller: tasksController,
            templateUrl: 'inline/tasks.html' //declared inline at app/views/tasks/index.html.erb
        });

    tasksController.$inject = ['$scope', '$timeout', 'api', 'urlParameter', 'contactCache'];

    function tasksController($scope, $timeout, api, urlParameter, contactCache) {
        var vm = this;

        vm.tasks = {};
        vm.comments = {};
        vm.people = {};
        vm.totalTasksLoading = true;
        vm.totalTasksShown = 0;

        vm.taskGroups = [
            {
                filter: 'today',
                title: 'Today',
                class: 'taskgroup--green',
                currentPage: 1,
                meta: {},
                loading: false,
                visible: false
            },
            {
                filter: 'overdue',
                title: 'Overdue',
                class: 'taskgroup--red',
                currentPage: 1,
                meta: {},
                loading: false,
                visible: false
            },
            {
                filter: 'tomorrow',
                title: 'Tomorrow',
                class: 'taskgroup--orange',
                currentPage: 1,
                meta: {},
                loading: false,
                visible: false
            },
            {
                filter: 'upcoming',
                title: 'Upcoming',
                class: 'taskgroup--gray',
                currentPage: 1,
                meta: {},
                loading: false,
                visible: false
            },
            {
                filter: 'history',
                title: 'History',
                class: 'taskgroup--gray',
                currentPage: 1,
                meta: {},
                loading: false,
                order: 'completed_at DESC',
                visible: false
            }
        ];


        vm.goToPage = goToPage;
        vm.refreshVisibleTasks = refreshVisibleTasks;
        vm.resetFilters = resetFilters;
        vm.isEmptyFilter = isEmptyFilter;
        vm.tagIsActive = tagIsActive;
        vm.tagClick = tagClick;

        activate();

        function activate(){
            vm.resetFilters(getLocationFilters());
            watchFilters();
            openContactFilter(); //auto-open contact filter
        }

        function goToPage(group, page) {
            vm.taskGroups[_.indexOf(vm.taskGroups, group)].currentPage = page;
            refreshTasks(group, vm.contactFilterIds);
        }

        function refreshVisibleTasks(contactIds) {
            if (contactFilterExists()) {
                if (!contactIds) {
                    getContactFilterIds();
                    return;
                } else {
                    if (contactIds.length === 0) {
                        contactIds[0] = '-'
                    }
                }
            } else {
                contactIds = vm.filter.contactsSelect;
            }

            angular.forEach(vm.taskGroups, function (g, key) {
                if (g.visible) {
                    refreshTasks(g, contactIds);
                }
            });
        }

        function contactFilterExists() {
            return (vm.filter.contactName !== '' || vm.filter.contactType !== '' || vm.filter.contactCity[0] !== ''
            || vm.filter.contactState[0] !== '' || vm.filter.contactCountry[0] !== '' || vm.filter.contactNewsletter !== ''
            || vm.filter.contactStatus[0] !== '' || vm.filter.contactLikely[0] !== '' || vm.filter.contactChurch[0] !== ''
            || vm.filter.contactReferrer[0] !== '' || vm.filter.contactTimezone[0] !== '' || vm.filter.contactPledgeFrequencies[0] !== ''
            || vm.filter.contactInfoEmail !== '' || vm.filter.contactInfoPhone !== '' || vm.filter.contactInfoMobile !== ''
            || vm.filter.contactInfoAddr !== '' || vm.filter.contactInfoFacebook !== '' );
        }

        function getContactFilterIds() {
            api.call('get', 'contacts?account_list_id=' + (window.current_account_list_id || '') +
                '&filters[name]=' + encodeURIComponent(vm.filter.contactName) +
                '&filters[contact_type]=' + encodeURIComponent(vm.filter.contactType) +
                '&filters[city][]=' + api.encodeURLarray(vm.filter.contactCity).join('&filters[city][]=') +
                '&filters[state][]=' + api.encodeURLarray(vm.filter.contactState).join('&filters[state][]=') +
                '&filters[country][]=' + api.encodeURLarray(vm.filter.contactCountry).join('&filters[country][]=') +
                '&filters[newsletter]=' + encodeURIComponent(vm.filter.contactNewsletter) +
                '&filters[status][]=' + api.encodeURLarray(vm.filter.contactStatus).join('&filters[status][]=') +
                '&filters[likely][]=' + api.encodeURLarray(vm.filter.contactLikely).join('&filters[likely][]=') +
                '&filters[church][]=' + api.encodeURLarray(vm.filter.contactChurch).join('&filters[church][]=') +
                '&filters[referrer][]=' + api.encodeURLarray(vm.filter.contactReferrer).join('&filters[referrer][]=') +
                '&filters[timezone][]=' + api.encodeURLarray(vm.filter.contactTimezone).join('&filters[timezone][]=') +
                '&filters[pledge_frequencies][]=' + api.encodeURLarray(vm.filter.contactPledgeFrequencies).join('&filters[pledge_frequencies][]=') +
                '&filters[contact_info_email]=' + encodeURIComponent(vm.filter.contactInfoEmail) +
                '&filters[contact_info_phone]=' + encodeURIComponent(vm.filter.contactInfoPhone) +
                '&filters[contact_info_mobile]=' + encodeURIComponent(vm.filter.contactInfoMobile) +
                '&filters[contact_info_addr]=' + encodeURIComponent(vm.filter.contactInfoAddr) +
                '&filters[contact_info_facebook]=' + encodeURIComponent(vm.filter.contactInfoFacebook) +
                '&include=Contact.id&per_page=10000'
                , {}, function (data) {
                    vm.contactFilterIds = _.pluck(data.contacts, 'id');
                    vm.refreshVisibleTasks(vm.contactFilterIds);
                }, null, true);
        }

        function refreshTasks(group, contactFilterIds) {
            var groupIndex = _.indexOf(vm.taskGroups, group);
            vm.taskGroups[groupIndex].loading = true;
            api.call('get', 'tasks?account_list_id=' + window.current_account_list_id +
                '&per_page=' + vm.filter.tasksPerGroup +
                '&page=' + group.currentPage +
                '&order=' + (group.order || 'start_at') +
                '&filters[starred]=' + vm.filter.starred +
                '&filters[completed]=' + (vm.filter.completed || 'false') +
                '&filters[date_range]=' + group.filter +
                '&filters[contact_ids]=' + _.uniq(contactFilterIds).join(',') +
                '&filters[tags][]=' + api.encodeURLarray(vm.filter.tagsSelect).join('&filters[tags][]=') +
                '&filters[activity_type][]=' + api.encodeURLarray(vm.filter.actionSelect).join('&filters[activity_type][]='), {}, function (tData) {

                //save meta
                vm.taskGroups[groupIndex].meta = tData.meta;

                if (tData.tasks.length === 0) {
                    if (vm.taskGroups[groupIndex].currentPage !== 1) {
                        vm.taskGroups[groupIndex].currentPage = 1;
                        refreshTasks(group);
                    }
                    vm.taskGroups[groupIndex].loading = false;
                    vm.tasks[group.filter] = {};
                    evalTaskTotals();
                    return;
                }

                //retrieve contacts
                api.call('get', 'contacts?account_list_id=' + window.current_account_list_id +
                    '&filters[status]=*&filters[ids]=' + _.chain(tData.tasks).pluck('contacts').flatten().unique().join().value(), {}, function (data) {
                    angular.forEach(data.contacts, function (contact) {
                        contactCache.update(contact.id, {
                            addresses: _.filter(data.addresses, function (addr) {
                                return _.contains(contact.address_ids, addr.id);
                            }),
                            people: _.filter(data.people, function (i) {
                                return _.contains(contact.person_ids, i.id);
                            }),
                            email_addresses: data.email_addresses,
                            contact: _.find(data.contacts, {'id': contact.id}),
                            phone_numbers: data.phone_numbers,
                            facebook_accounts: data.facebook_accounts
                        });
                    });

                    vm.tasks[group.filter] = tData.tasks;
                    vm.comments = _.union(tData.comments, vm.comments);
                    vm.people = _.union(tData.people, vm.people);

                    vm.taskGroups[groupIndex].loading = false;
                    evalTaskTotals();
                }, null, true);
            });
        }

        function blankFilterObject() {
            return {
                page: 'all',
                starred: '',
                completed: '',
                contactsSelect: [(urlParameter.get('contact_ids') || '')],
                tagsSelect: [''],
                actionSelect: [''],
                contactName: '',
                contactType: '',
                contactCity: [''],
                contactState: [''],
                contactCountry: [''],
                contactNewsletter: '',
                contactStatus: [''],
                contactLikely: [''],
                contactChurch: [''],
                contactReferrer: [''],
                contactTimezone: [''],
                contactPledgeFrequencies: [''],
                contactInfoEmail: '',
                contactInfoPhone: '',
                contactInfoMobile: '',
                contactInfoAddr: '',
                contactInfoFacebook: '',
                tasksPerGroup: 25
            };
        }

        function resetFilters(overrides) {
            overrides = overrides || {}
            vm.filter = _.extend(blankFilterObject(), overrides);
        }

        function getLocationFilters() {
            if (!window.location || !window.location.search)
                return {};
            var filterOverrides = {};
            var locationFilters = decodeURIComponent(location.search.substr(1)).split('&');
            angular.forEach(locationFilters, function (filter) {
                if (filter.indexOf('filters') != 0 || filter.indexOf('=') == -1)
                    return;
                var key = filter.split('=')[0].slice("filters[".length, -1),
                    val = filter.split('=')[1].split('+').join(' ')
                if (key.indexOf('][') != -1 && val) {
                    var arrayName = key.slice(0, -2);
                    filterOverrides[arrayName] = filterOverrides[arrayName] || [];
                    filterOverrides[arrayName].push(val);
                }
                else {
                    filterOverrides[key] = val
                }
            });
            return filterOverrides;
        }

        function isEmptyFilter() {
            return _.isEqual(vm.filter, blankFilterObject());
        }

        function watchFilters() {
            $scope.$watch('$ctrl.filter', function (f, oldf) {
                vm.filter.starred = f.page == 'starred' ? 'true' : ''
                vm.filter.completed = f.page == 'history' ? 'true' : ''

                vm.taskGroups[0].visible = true;
                vm.taskGroups[1].visible = true;
                vm.taskGroups[2].visible = true;
                vm.taskGroups[3].visible = true;
                vm.taskGroups[4].visible = false;

                switch (f.page) {
                    case 'today':
                        vm.taskGroups[1].visible = false;
                        vm.taskGroups[2].visible = false;
                        vm.taskGroups[3].visible = false;
                        break;
                    case 'overdue':
                        vm.taskGroups[0].visible = false;
                        vm.taskGroups[2].visible = false;
                        vm.taskGroups[3].visible = false;
                        break;
                    case 'upcoming':
                        vm.taskGroups[0].visible = false;
                        vm.taskGroups[1].visible = false;
                        break;
                    case 'history':
                        vm.taskGroups[0].visible = false;
                        vm.taskGroups[1].visible = false;
                        vm.taskGroups[2].visible = false;
                        vm.taskGroups[3].visible = false;
                        vm.taskGroups[4].visible = true;
                        break;
                }
                vm.refreshVisibleTasks();
            }, true);
        }

        function evalTaskTotals() {
            //total tasks
            vm.totalTasksShown = 0;
            angular.forEach(vm.taskGroups, function (g, key) {
                if (!_.isUndefined(vm.tasks[g.filter]) && g.visible) {
                    if (!_.isEmpty(vm.tasks[g.filter])) {
                        vm.totalTasksShown = vm.totalTasksShown + vm.tasks[g.filter].length;
                    }
                }
            });
            $timeout(function () {
                vm.totalTasksLoading = _.some(vm.taskGroups, 'loading', true);
            }, 1000);
        }

        function openContactFilter() {
            if (vm.filter.contactsSelect[0]) {
                jQuery("#leftmenu ul.left_filters li #contact").trigger("click");
                vm.filter.page = 'all';
            }
        }

        function tagIsActive(tag) {
            return _.contains(vm.filter.tagsSelect, tag);
        }

        function tagClick(tag, $event) {
            if ($event && $event.target.attributes['data-method'])
                return;
            if (tagIsActive(tag)) {
                _.remove(vm.filter.tagsSelect, function (i) {
                    return i === tag;
                });
                if (vm.filter.tagsSelect.length === 0) {
                    vm.filter.tagsSelect.push('');
                }
            } else {
                _.remove(vm.filter.tagsSelect, function (i) {
                    return i === '';
                });
                vm.filter.tagsSelect.push(tag);
            }
        };
    }
})();
