$ ->
  if $('#accounts_index')[0]? || $('#csv_import_preview')[0]? || $('#setup_show')[0]?
    $(document).on 'change', '#organization_id', (e) ->
      $('#connect_to_org').toggleClass('disabled', !e.target.value)

  $(document).on 'click', '#connect_to_org', ->
    return false if $('#organization_id').val() == ''
    el = $('#org_connection_box')
    el.dialog
      resizable: false,
      height:'auto',
      width:400,
      modal: true

    $.ajax {
      url: $(this).attr('href'),
      data: {id: $('#organization_id').val()},
      dataType: 'script'
    }
    false

  $('.missing_org_btn').click ->
    $('#missing_org_modal').dialog
      resizable: false,
      height: 'auto',
      width: 500
    false
