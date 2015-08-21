$ ->
  if $('.google_integrations_controller')[0]?
    $(document).on 'click', '#new_calendar_link', ->
      $(this).hide()
      $('#new_calendar_form').show()

    $(document).on 'change', '[data-behavior=calendar_integration]', ->
      calendar_form = $(this).closest('form')
      $.post(calendar_form.attr('action'), calendar_form.serialize(), ->
        $.mpdx.toast(__('Calendar integration updated!')))
      true
