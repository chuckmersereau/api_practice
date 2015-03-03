$ ->

  $().ready ->
  numberOfRows = $('#recurringGiftsDataTable tbody tr').length
  $('#nextAskYearMonth').replaceWith('<td>' +  $.datepicker.formatDate 'yy / mm' + '</td>', new Date $('#nextAskYearMonth').text() ) for num in [0..numberOfRows]

  $("table tbody tr").on 'dblclick', ->
    cName = $(this).data('id')
    $("."+ cName).slideToggle("fast")

  $(document).on 'click', '#btn', (e) ->
    e.preventDefault
    selectedResult = $(this).prev().find('select option:selected').text()
    selectedRecurringContactId = $(this).parent().data('id')
    $.ajax {
      url: '/insights',
      data: {'selResult':selectedResult,'selectedRecurringContactId':selectedRecurringContactId } ,
      type: 'POST'
    }


  $("#recurringGiftsDataTable").sortable();