$ ->

  $().ready ->
  numberOfrows = $('#recurringGiftsDataTable tbody tr').length
  i=0
  while numberOfrows > i
    ++i
    dateFormat = $('#nextAskYearMonth').text()
    dateFormat = $.datepicker.formatDate('yy / mm', new Date(dateFormat))
    $('#nextAskYearMonth').replaceWith(dateFormat)

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
