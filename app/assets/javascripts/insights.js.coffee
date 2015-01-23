$ ->
  $().ready ->
    numberOfrows = document.getElementById("recurringGiftsDataTable").rows.length
    i=0
    while numberOfrows > i
       ++i
       dateFormat = $('#nextAskYearMonth').text()
       dateFormat = $.datepicker.formatDate('yy / mm', new Date(dateFormat))
       $('#nextAskYearMonth').replaceWith(dateFormat)

  $("table tbody tr").on 'dblclick', ->
    cName = $(this).data('id')
    $("."+ cName).slideToggle("fast")

  $(document).on 'click', '#submit_status', ->
    cName = $(this).parent().parent().data('id')
    $("."+ cName).slideToggle("fast")