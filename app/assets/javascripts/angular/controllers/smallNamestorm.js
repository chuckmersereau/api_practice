angular.module('mpdxApp').controller('smallNamestorm', function (api) {
  this.contacts = [];
  this.newContactName = '';
  this.newContactStatus = 'Contact for Appointment';
  this.contactStatuses = ["Never Contacted","Ask in Future","Cultivate Relationship",
                          "Contact for Appointment","Appointment Scheduled","Call for Decision",
                          "Partner - Financial","Partner - Special","Partner - Pray",
                          "Not Interested","Unresponsive","Never Ask","Research Abandoned",
                          "Expired Referral"];
  this.contactStatuses = _.map(this.contactStatuses, function(status) {
    return { value: status, text: __(status) };
  });

  this.addContact = function() {
    var scope = this;
    this.apiBusy = true;
    this.error = '';
    api.post('contacts/?account_list_id=' + window.current_account_list_id,
             { contact: { name: this.newContactName, status: this.newContactStatus } })
       .success(function(response) {
        scope.contacts.push({id: response.contact.id, name: response.contact.name});
        scope.newContactName = '';
      })
      .error(function(response) {
        scope.error = __("Ouch! There was an error with your request. Sorry!");
      })
      .then(function() {
        scope.apiBusy= false;
        setTimeout(function(){
          jQuery('#welcome-new-contact-name').focus();
        });
      });
  };
});
