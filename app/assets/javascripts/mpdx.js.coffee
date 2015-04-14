$ ->
# Activating Best In Place
  $('.best_in_place').best_in_place()
  $('.best_in_place_once').on 'best_in_place:success', ->
    elm = this
    setTimeout ->
      $(elm).unbind('click').removeClass('best_in_place_once').removeClass('best_in_place')

  $(document).on 'best_in_place:success', (event, request, error) ->
    $.mpdx.toast(__("Contact Updated!"))
  $(document).on 'best_in_place:error', (event, request, error) ->
    $.mpdx.toast(__("Contact Save Failed"))

  $(document).on 'change', '#per_page', ->
    params = $.set_param('per_page', $(this).val())
    params = $.set_param('page', 1, params)
    document.location = document.location.pathname + '?' + params

  $(document).on 'click', '.filter_title', ->
    $(this).toggleClass("opened")
    $(this).parent("li").toggleClass("opened")
    determineAffixScroll()

  $(document).on 'mouseleave', 'div[data-behavior=account_selector]', ->
    $('div[data-behavior=account_selector] div').hide()
    false

  $(document).on 'click', 'a[data-behavior=current_account]', ->
    $('div[data-behavior=account_selector] div').toggle()
    false

  if $('.inside.notice')[0]?
    setTimeout ->
      $('.inside.notice').fadeOut('fast')
    , 6000

  current_time = new Date()
  $.cookie('timezone', current_time.getTimezoneOffset(), { path: '/', expires: 10 } )

  # get rid of download notification when all accounts are done downloading
  if $('#data_downloading')[0]?
    data_download_interval = setInterval ->
      $.get '/home/download_data_check', (data)->
        if data == 'false'
          clearInterval(data_download_interval)
          $('#data_downloading').remove()
    , 5000

  $(document).on 'click', '.item .dismiss_item', ->
    $(this).parent().fadeOut("fast")
    false

  $(window).on 'statechange', ->
    if _gaq?
      state = History.getState()
      relativeUrl = state.url.replace(History.getRootUrl(),'')
      _gaq.push(['_trackPageview', relativeUrl])

  $.mpdx.activateTabs()

  $(document).on 'click', 'div[remote=true] a', ->
    $(this).attr('data-remote', true)
    $.rails.handleRemote($(this))
    false

  $(document).on 'click', 'a[data-behavior=remove_field]', ->
    link = this
    $(link).prev("input[type=hidden]").val("1")
    field_wrapper = $(link).closest("[data-behavior*=field-wrapper]")
    field_wrapper.hide()
    field_wrapper.find(':input:not([type=hidden])').attr('disabled', true)
    fieldset = $(link).closest('.fieldset')
    false

  $(document).on 'ajax:before', '[data-method=delete]', ->
    if $(this).attr('data-selector')?
      $(this).closest($(this).attr('data-selector')).fadeOut()
    else
      $(this).parent().fadeOut()

  $(document).on 'ajax:before', 'a', ->
    $.mpdx.ajaxBefore()

  $(document).ajaxComplete ->
    $('#page_spinner').dialog('close') if $('#page_spinner').hasClass('ui-dialog-content')

  $(document).on 'click', 'a.no-new-tab', (event) ->
    event.target.click()
    false

window.addFields = (link, association, content) ->
  new_id = new Date().getTime()
  regexp = new RegExp("new_" + association, "g")
  new_field = $(content.replace(regexp, new_id))
  $(link).closest(".sfield").before(new_field)
  fieldset = $(link).closest('[data-behavior*=add-wrapper]')
  $('.field_action', fieldset).show() # delete buttons
  $('input', new_field).focus()
  $('.country_select').selectToAutocomplete()
  false

$.mpdx = {}
$.mpdx.activateTabs = ->
  $(".tabgroup").tabs({
    activate: (event, ui) ->
      #window.location.hash = ui.newPanel[0].id
  })

$.mpdx.ajaxBefore = ->
  $('#page_spinner').dialog({modal: true, closeOnEscape: false})

$.mpdx.sortableTabs = (location) ->
  # draggable ui tabs
  container = '#'+location+' .ui-tabs-nav'
  $(container).sortable({
    axis: 'x',
    update: (event, ui) ->
      data = $(container).sortable('serialize')
      data += "&location=" + location

      $.ajax {
        url: '/preferences/update_tab_order',
        data: data,
        type: 'POST',
        mode: 'abort'
      }
  }).disableSelection()

# Stub method for translation
window.__ = (val) ->
  val

# Replace built in rails confirmation method
$.rails.allowAction = (element) ->
  message = element.data('confirm')
  if message
    div = $('#confirmation_modal')
    div.html(message)
    div.dialog {
      buttons: [
        {
          text: __('Yes'),
          click: ->
            $.rails.confirmed(element)
            $(this).dialog("close")
        },
        {
          text: __('No'),
          click: ->
            $(this).dialog("close")
        },
      ]
    }
    false
  else
    true

$.rails.confirmed = (element) ->
  element.removeAttr('data-confirm')
  element.removeData('confirm')
  element.trigger('click.rails')

$.deparam = (param_string) ->
  s = param_string || document.location.search
  querystring = s.replace( /(?:^[^?#]*\?([^#]*).*$)?.*/, '$1' )
  obj = {}

  $.each querystring.replace(/\+/g, " ").split("&"), (j, v) ->
    param = v.split("=")
    key = decodeURIComponent(param[0])
    val = undefined
    cur = obj
    i = 0
    keys = key.split("][")
    keys_last = keys.length - 1
    if /\[/.test(keys[0]) and /\]$/.test(keys[keys_last])
      keys[keys_last] = keys[keys_last].replace(/\]$/, "")
      keys = keys.shift().split("[").concat(keys)
      keys_last = keys.length - 1
    else
      keys_last = 0
    if param.length is 2
      val = decodeURIComponent(param[1])
      if keys_last
        while i <= keys_last
          key = (if keys[i] is "" then cur.length else keys[i])
          cur = cur[key] = (if i < keys_last then cur[key] or (if keys[i + 1] and isNaN(keys[i + 1]) then {} else []) else val)
          i++
      else
        if $.isArray(obj[key])
          obj[key].push val
        else if obj[key] isnt `undefined`
          obj[key] = [ obj[key], val ]
        else
          obj[key] = val
    else obj[key] = "" if key

  obj

$.mpdx.setOptions = (select_tag, options) ->
  select_tag.empty()
  $.each options.split(','), (key, value) ->
    select_tag.append $("<option></option>").attr("value", value).text(value)

$.mpdx.toast = (options) ->
  if typeof options == "string"
    options = { message: options }
  duration = options.duration || 2000
  $('#toastPopup').text(options.message).fadeIn(300).delay(duration).fadeOut(300)

$.set_param = (key, value, params) ->
  params = '?' + params if params
  params = $.deparam(params)
  params[key] = value
  $.param(params)

$(document).ready ->
  element = $.deparam(location.search).focus
  $('#' + element).focus() if element

determineAffixScroll = ->
  $('#leftmenu').toggleClass 'scrollable_left', $(window).height() < $('#leftmenu').height()
  return

$(document).ready determineAffixScroll
$(window).on 'resize', determineAffixScroll

$(document).ready ->
  $('.toggle-mobile-filters').click ->
    $('html, body').animate { scrollTop: 0 }, 0
    $('.mobile_filters_wrap').toggleClass 'show_mobile_filters'
    $('body').toggleClass 'stopscroll'
    return
