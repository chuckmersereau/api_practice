angular.module('mpdxApp').controller('tasksController', function ($scope, $timeout, api, urlParameter, contactCache) {
    $scope.tasks = {};
    $scope.comments = {};
    $scope.people = {};
    $scope.totalTasksLoading = true;
    $scope.totalTasksShown = 0;

    $scope.taskGroups = [
        {
            filter:'today',
            title: 'Today',
            class: 'taskgroup--green',
            currentPage: 1,
            meta: {},
            loading: false,
            visible: false
        },
        {
            filter:'overdue',
            title: 'Overdue',
            class: 'taskgroup--red',
            currentPage: 1,
            meta: {},
            loading: false,
            visible: false
        },
        {
            filter:'tomorrow',
            title: 'Tomorrow',
            class: 'taskgroup--orange',
            currentPage: 1,
            meta: {},
            loading: false,
            visible: false
        },
        {
            filter:'upcoming',
            title: 'Upcoming',
            class: 'taskgroup--gray',
            currentPage: 1,
            meta: {},
            loading: false,
            visible: false
        },
        {
            filter:'history',
            title: 'History',
            class: 'taskgroup--gray',
            currentPage: 1,
            meta: {},
            loading: false,
            order: 'completed_at DESC',
            visible: false
        }
    ];


    $scope.goToPage = function(group, page){
        $scope.taskGroups[_.indexOf($scope.taskGroups, group)].currentPage = page;
        refreshTasks(group,$scope.contactFilterIds);
    };

    $scope.refreshVisibleTasks = function(contactIds){
        if(contactFilterExists()){
            if(!contactIds) {
                getContactFilterIds();
                return;
            }else{
                if(contactIds.length === 0){
                    contactIds[0] = '-'
                }
            }
        }else{
            contactIds = $scope.filter.contactsSelect;
        }

        angular.forEach($scope.taskGroups, function(g, key){
            if(g.visible){
                refreshTasks(g,contactIds);
            }
        });
    };

    var contactFilterExists = function(){
        return ($scope.filter.contactName !==  '' || $scope.filter.contactType !== '' || $scope.filter.contactCity[0] !== ''
            || $scope.filter.contactState[0] !== '' || $scope.filter.contactCountry[0] !== '' || $scope.filter.contactNewsletter !== ''
            || $scope.filter.contactStatus[0] !== '' || $scope.filter.contactLikely[0] !== '' || $scope.filter.contactChurch[0] !== ''
            || $scope.filter.contactReferrer[0] !== '' || $scope.filter.contactTimezone[0] !== '' || $scope.filter.contactPledgeFrequencies[0] !== ''
            || $scope.filter.contactInfoEmail !== '' || $scope.filter.contactInfoPhone !== '' || $scope.filter.contactInfoMobile !== ''
            || $scope.filter.contactInfoAddr !== '' || $scope.filter.contactInfoFacebook !== '' );
    };

    var getContactFilterIds = function(){
        api.call('get','contacts?account_list_id=' + (window.current_account_list_id || '') +
            '&filters[name]=' + encodeURIComponent($scope.filter.contactName) +
            '&filters[contact_type]=' + encodeURIComponent($scope.filter.contactType) +
            '&filters[city][]=' + encodeURLarray($scope.filter.contactCity).join('&filters[city][]=') +
            '&filters[state][]=' + encodeURLarray($scope.filter.contactState).join('&filters[state][]=') +
            '&filters[country][]=' + encodeURLarray($scope.filter.contactCountry).join('&filters[country][]=') +
            '&filters[newsletter]=' + encodeURIComponent($scope.filter.contactNewsletter) +
            //'&filters[tags][]=' + encodeURLarray(q.tags).join('&filters[tags][]=') +
            '&filters[status][]=' + encodeURLarray($scope.filter.contactStatus).join('&filters[status][]=') +
            '&filters[likely][]=' + encodeURLarray($scope.filter.contactLikely).join('&filters[likely][]=') +
            '&filters[church][]=' + encodeURLarray($scope.filter.contactChurch).join('&filters[church][]=') +
            '&filters[referrer][]=' + encodeURLarray($scope.filter.contactReferrer).join('&filters[referrer][]=') +
            '&filters[timezone][]=' + encodeURLarray($scope.filter.contactTimezone).join('&filters[timezone][]=') +
            '&filters[pledge_frequencies][]=' + encodeURLarray($scope.filter.contactPledgeFrequencies).join('&filters[pledge_frequencies][]=') +
            '&filters[contact_info_email]=' + encodeURIComponent($scope.filter.contactInfoEmail) +
            '&filters[contact_info_phone]=' + encodeURIComponent($scope.filter.contactInfoPhone) +
            '&filters[contact_info_mobile]=' + encodeURIComponent($scope.filter.contactInfoMobile) +
            '&filters[contact_info_addr]=' + encodeURIComponent($scope.filter.contactInfoAddr) +
            '&filters[contact_info_facebook]=' + encodeURIComponent($scope.filter.contactInfoFacebook) +
            '&include=Contact.id&per_page=10000'
        , {}, function(data) {
             $scope.contactFilterIds = _.pluck(data.contacts, 'id');
             $scope.refreshVisibleTasks($scope.contactFilterIds);
        }, null, true);
    };

    var refreshTasks = function(group, contactFilterIds){
        var groupIndex = _.indexOf($scope.taskGroups, group);
        $scope.taskGroups[groupIndex].loading = true;
        api.call('get','tasks?account_list_id=' + window.current_account_list_id +
            '&per_page=' + $scope.filter.tasksPerGroup +
            '&page=' + group.currentPage +
            '&order=' + (group.order || 'start_at') +
            '&filters[starred]=' + $scope.filter.starred +
            '&filters[completed]=' + ($scope.filter.completed || 'false') +
            '&filters[date_range]=' + group.filter +
            '&filters[contact_ids]=' + _.uniq(contactFilterIds).join(',') +
            '&filters[tags][]=' + encodeURLarray($scope.filter.tagsSelect).join('&filters[tags][]=') +
            '&filters[activity_type][]=' + encodeURLarray($scope.filter.actionSelect).join('&filters[activity_type][]='), {}, function(tData) {

            //save meta
            $scope.taskGroups[groupIndex].meta = tData.meta;

            if(tData.tasks.length === 0){
                if($scope.taskGroups[groupIndex].currentPage !== 1){
                    $scope.taskGroups[groupIndex].currentPage = 1;
                    refreshTasks(group);
                }
                $scope.taskGroups[groupIndex].loading = false;
                $scope.tasks[group.filter] = {};
                evalTaskTotals();
                return;
            }

            //retrieve contacts
            api.call('get','contacts?account_list_id=' + window.current_account_list_id +
                '&filters[status]=*&filters[ids]='+_.chain(tData.tasks).pluck('contacts').flatten().unique().join().value(), {} ,function(data) {
                angular.forEach(data.contacts, function(contact){
                    contactCache.update(contact.id, {
                        addresses: _.filter(data.addresses, function (addr) {
                            return _.contains(contact.address_ids, addr.id);
                        }),
                        people: _.filter(data.people, function (i) {
                            return _.contains(contact.person_ids, i.id);
                        }),
                        email_addresses: data.email_addresses,
                        contact: _.find(data.contacts, { 'id': contact.id }),
                        phone_numbers: data.phone_numbers,
                        facebook_accounts: data.facebook_accounts
                    });
                });

                $scope.tasks[group.filter] = tData.tasks;
                $scope.comments = _.union(tData.comments, $scope.comments);
                $scope.people = _.union(tData.people, $scope.people);

                $scope.taskGroups[groupIndex].loading = false;
                evalTaskTotals();
            }, null, true);
        });
    };

    var blankFilterObject = function() {
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
    $scope.resetFilters = function(){
        $scope.filter = blankFilterObject();
    };
    $scope.resetFilters();

    $scope.isEmptyFilter = function() {
        return _.isEqual($scope.filter, blankFilterObject());
    }

    $scope.$watch('filter', function (f, oldf) {
        $scope.filter.starred = f.page == 'starred' ? 'true' : ''
        $scope.filter.completed = f.page == 'history' ? 'true' : ''

        $scope.taskGroups[0].visible = true;
        $scope.taskGroups[1].visible = true;
        $scope.taskGroups[2].visible = true;
        $scope.taskGroups[3].visible = true;
        $scope.taskGroups[4].visible = false;

        switch(f.page) {
            case 'today':
                $scope.taskGroups[1].visible = false;
                $scope.taskGroups[2].visible = false;
                $scope.taskGroups[3].visible = false;
                break;
            case 'overdue':
                $scope.taskGroups[0].visible = false;
                $scope.taskGroups[2].visible = false;
                $scope.taskGroups[3].visible = false;
                break;
            case 'upcoming':
                $scope.taskGroups[0].visible = false;
                $scope.taskGroups[1].visible = false;
                break;
            case 'history':
                $scope.taskGroups[0].visible = false;
                $scope.taskGroups[1].visible = false;
                $scope.taskGroups[2].visible = false;
                $scope.taskGroups[3].visible = false;
                $scope.taskGroups[4].visible = true;
                break;
        }
        $scope.refreshVisibleTasks();
    }, true);

    var evalTaskTotals = function(){
        //total tasks
        $scope.totalTasksShown = 0;
        angular.forEach($scope.taskGroups, function(g, key){
            if(!_.isUndefined($scope.tasks[g.filter]) && g.visible){
                if(!_.isEmpty($scope.tasks[g.filter])){
                    $scope.totalTasksShown = $scope.totalTasksShown + $scope.tasks[g.filter].length;
                }
            }
        });
        $timeout(function(){
            $scope.totalTasksLoading = _.some($scope.taskGroups, 'loading', true);
        }, 1000);
    };

    //auto-open contact filter
    if($scope.filter.contactsSelect[0]){
        jQuery("#leftmenu ul.left_filters li #contact").trigger("click");
        $scope.filter.page = 'all';
    }

    $scope.tagIsActive = function(tag){
        return _.contains($scope.filter.tagsSelect, tag);
    };

    $scope.tagClick = function(tag, $event){
        if($event && $event.target.attributes['data-method'])
            return;
        if($scope.tagIsActive(tag)){
            _.remove($scope.filter.tagsSelect, function(i) { return i === tag; });
            if($scope.filter.tagsSelect.length === 0){
                $scope.filter.tagsSelect.push('');
            }
        }else{
            _.remove($scope.filter.tagsSelect, function(i) { return i === ''; });
            $scope.filter.tagsSelect.push(tag);
        }
    };

/*    $scope.contactTagIsActive = function(tag){
        return _.contains($scope.filterContactTagSelect, tag);
    };

    $scope.contactTagClick = function(tag){
        if($scope.contactTagIsActive(tag)){
            _.remove($scope.filterContactTagSelect, function(i) { return i === tag; });
            if($scope.filterContactTagSelect.length === 0){
                $scope.filterContactTagSelect.push('');
            }
        }else{
            _.remove($scope.filterContactTagSelect, function(i) { return i === ''; });
            $scope.filterContactTagSelect.push(tag);
        }
    };*/
});
