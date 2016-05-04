(function() {
    angular
        .module('mpdxApp')
        .factory('selectionStore', selectionStore);

    selectionStore.$inject = ['$localForage', '$log', 'state'];

    function selectionStore($localForage, $log, state) {
        var service = {
            loadSelectedContacts: loadSelectedContacts,
            saveSelectedContacts: saveSelectedContacts
        };

        // This returns a promise from localForage for the retrieved contacts.
        function loadSelectedContacts() {
            return $localForage.getItem(selectedContactsStorageKey());
        }

        // Since handling the promise case for a successful save is trivial and
        // for a failure case we just log it, then just handle the promise here
        // to avoid duplication in the callers of it.
        function saveSelectedContacts(selectedContacts) {
            $localForage.setItem(selectedContactsStorageKey(), selectedContacts).then(
                function(){},
                function(){
                    $log.error('Failed to save selected contacts');
                });
        }

        function selectedContactsStorageKey(){
            return 'selectedContacts-userId:' + state.current_user_id + '-accountListId:' + state.current_account_list_id;
        }

        return service;
    }
})();
