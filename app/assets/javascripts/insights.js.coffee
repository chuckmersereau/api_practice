$ ->
  $().ready ->
    numberOfrows = document.getElementById("recurringGiftsDataTable").rows.length
    i=0
    while numberOfrows > i
       ++i
       dateFormat = $('#nextAskYearMonth').text()
       dateFormat = $.datepicker.formatDate('yy / mm', new Date(dateFormat))
       $('#nextAskYearMonth').replaceWith(dateFormat)

