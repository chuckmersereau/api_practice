$ ->

$(document).on 'ready page:load', ->
  $('#recurringGiftsDataTable tr td.nextAskYearMonth').each(index, element) =>

  dateFormat =  $(this).text();
  dateFormat = $.datepicker.formatDate('yy / mm', new Date(dateFormat));

  $(this).html(dateFormat);
