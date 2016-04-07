$ ->
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

  if $("body[setup-step='settings']")[0]
    preferences_prefills = JSON.parse($('#preference_set_preferences_prefills').val())

    fill_preferences_form_with = (settings) ->
      if settings.country
        $('#preference_set_ministry_country').val(settings.country).highlight()
        $('#preference_set_home_country').val(settings.country).highlight()
      if settings.currency
        $('#preference_set_currency').val(settings.currency).highlight()

    if Object.keys(preferences_prefills).length = 1
      fill_preferences_form_with(preferences_prefills[Object.keys(preferences_prefills)[0]])

    $(document).on 'change', '#preferences_prefill_options', ->
      fill_preferences_form_with(preferences_prefills[$(this).val()])

jQuery.fn.highlight = ->
  $(this).each ->
    el = $(this).parent()
    el.before("<div/>")
    el.prev()
        .width(el.width())
        .height(el.height())
        .css({
          "position": "absolute",
          "background-color": "#ffff99",
          "opacity": ".7"
        })
        .fadeOut(500, ->
          $(this).remove();
    );
