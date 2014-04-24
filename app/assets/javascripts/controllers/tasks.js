angular.module('mpdxApp').controller('tasksController', function ($scope, $filter, $location, api, urlParameter, contactCache) {
    $scope.refreshTasks = function(){
        api.call('get','tasks?filters[completed]=false',{},function(data) {
            $scope.tasks = data.tasks;
            $scope.comments = data.comments;
            $scope.people = data.people;

            $scope.tags = _.sortBy(_.uniq(_.flatten(_.pluck($scope.tasks, 'tag_list'))));
            $scope.tags = _.zip($scope.tags, $scope.tags);
            $scope.tags.unshift(['', '-- Any --']);

            $scope.activity_types = _.sortBy(_.uniq(_.pluck($scope.tasks, 'activity_type')));
            _.remove($scope.activity_types, function(action) { return action === ''; });
            $scope.activity_types = _.zip($scope.activity_types, $scope.activity_types);
            $scope.activity_types.unshift(['', '-- Any --']);

            $scope.contactStatusOptions = [['', '-- Any --']];
            $scope.contactLikelyToGiveOptions = [['', '-- Any --']];
            //pre-cache contact details
            angular.forEach(_.uniq(_.flatten($scope.tasks, 'contacts')), function(contact){
                contactCache.get(contact, function(contact){
                    //contact status
                    if(angular.isUndefined(_.find($scope.contactStatusOptions, function(i){ return i[0] === contact.contact.status; }))){
                        $scope.contactStatusOptions.push([contact.contact.status, contact.contact.status]);
                        $scope.contactStatusOptions = _.sortBy($scope.contactStatusOptions, function(i) { return i[0]; });
                    }

                    //contact likely to give
                    if(angular.isUndefined(_.find($scope.contactLikelyToGiveOptions, function(i){ return i[0] === contact.contact.likely_to_give; }))){
                        $scope.contactLikelyToGiveOptions.push([contact.contact.likely_to_give, contact.contact.likely_to_give]);
                        $scope.contactLikelyToGiveOptions = _.sortBy($scope.contactLikelyToGiveOptions, function(i) { return i[0]; });
                    }
                });
            });

        });
    };
    $scope.refreshTasks();
    $scope.filterContactsSelect = [(urlParameter.get('contact_ids') || '')];
    $scope.filterContactCitySelect = [''];
    $scope.filterContactStateSelect = [''];
    $scope.filterContactNewsletterSelect = '';
    $scope.filterContactStatusSelect = [''];
    $scope.filterContactLikelyToGiveSelect = [''];
    $scope.filterContactChurchSelect = [''];
    $scope.filterContactReferrerSelect = [''];
    $scope.filterTagsSelect = [''];
    $scope.filterActionSelect = [''];
    $scope.filterPage = ($location.$$url === '/starred' ? "starred" : 'active');

    //auto-open contact filter
    if($scope.filterContactsSelect[0]){
        jQuery("#leftmenu ul.left_filters li #contact").trigger("click");
    }

    $scope.tagIsActive = function(tag){
        return _.contains($scope.filterTagsSelect, tag);
    };

    $scope.tagClick = function(tag){
        if($scope.tagIsActive(tag)){
            _.remove($scope.filterTagsSelect, function(i) { return i === tag; });
            if($scope.filterTagsSelect.length === 0){
                $scope.filterTagsSelect.push('');
            }
        }else{
            _.remove($scope.filterTagsSelect, function(i) { return i === ''; });
            $scope.filterTagsSelect.push(tag);
        }
    };

    $scope.filters = function(task){
        var filterContact = false;
        if($scope.filterContactsSelect[0] === ''){
            filterContact = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.contains($scope.filterContactsSelect, contact.toString())){
                    filterContact = true;
                }
            });
        }

        var filterContactCity = false;
        if($scope.filterContactCitySelect[0] === ''){
            filterContactCity = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.intersection(_.flatten(contactCache.getFromCache(contact).addresses, 'city'), $scope.filterContactCitySelect).length > 0){
                    filterContactCity = true;
                }
            });
        }

        var filterContactState = false;
        if($scope.filterContactStateSelect[0] === ''){
            filterContactState = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.intersection(_.flatten(contactCache.getFromCache(contact).addresses, 'state'), $scope.filterContactStateSelect).length > 0){
                    filterContactState = true;
                }
            });
        }

        var filterContactNewsletters = false;
        if($scope.filterContactNewsletterSelect === ''){
            filterContactNewsletters = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if($scope.filterContactNewsletterSelect === contactCache.getFromCache(contact).contact.send_newsletter){
                    filterContactNewsletters = true;
                }
            });
        }

        var filterContactStatus = false;
        if($scope.filterContactStatusSelect[0] === ''){
            filterContactStatus = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.contains($scope.filterContactStatusSelect, contactCache.getFromCache(contact).contact.status)){
                    filterContactStatus = true;
                }
            });
        }

        var filterContactLikelyToGive = false;
        if($scope.filterContactLikelyToGiveSelect[0] === ''){
            filterContactLikelyToGive = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.contains($scope.filterContactLikelyToGiveSelect, contactCache.getFromCache(contact).contact.likely_to_give)){
                    filterContactLikelyToGive = true;
                }
            });
        }

        var filterContactChurch = false;
        if($scope.filterContactChurchSelect[0] === ''){
            filterContactChurch = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                if(_.contains($scope.filterContactChurchSelect, contactCache.getFromCache(contact).contact.church_name)){
                    filterContactChurch = true;
                }
            });
        }

        var filterContactReferrer = false;
        if($scope.filterContactReferrerSelect[0] === ''){
            filterContactReferrer = true;
        }else{
            angular.forEach(task.contacts, function(contact){
                var referralsStrings = [];
                angular.forEach(contactCache.getFromCache(contact).contact.referrals_to_me_ids, function(id){
                    referralsStrings.push(id.toString());
                });
                if(_.intersection(referralsStrings, $scope.filterContactReferrerSelect).length > 0){
                    filterContactReferrer = true;
                }
            });
        }

        var filterTag = false;
        if(_.intersection(task.tag_list, $scope.filterTagsSelect).length > 0 || $scope.filterTagsSelect[0] === ''){
            filterTag = true;
        }

        var filterAction = false;
        if(_.contains($scope.filterActionSelect, task.activity_type) || $scope.filterActionSelect[0] === ''){
            filterAction = true;
        }

        var filterPage = false;
        if($scope.filterPage === 'active'){
            filterPage = true;
        }else if($scope.filterPage === 'starred'){
            filterPage = task.starred;
        }
        return filterContact && filterContactCity && filterContactState && filterContactNewsletters && filterContactStatus && filterContactLikelyToGive && filterContactChurch && filterContactReferrer && filterTag && filterAction && filterPage;
    };

    $scope.filterToday = function(task) {
        return ($filter('date')(task.due_date, 'yyyyMMdd') === $filter('date')(Date.now(), 'yyyyMMdd'));
    };

    $scope.filterOverdue= function(task) {
        return ($filter('date')(task.due_date, 'yyyyMMdd') < $filter('date')(Date.now(), 'yyyyMMdd'));
    };

    $scope.filterTomorrow= function(task) {
        return ($filter('date')(task.due_date, 'yyyyMMdd') === $filter('date')(new Date(new Date().getTime() + 24 * 60 * 60 * 1000), 'yyyyMMdd'));
    };

    $scope.filterUpcoming= function(task) {
        return ($filter('date')(task.due_date, 'yyyyMMdd') > $filter('date')(new Date(new Date().getTime() + 24 * 60 * 60 * 1000), 'yyyyMMdd'));
    };
});