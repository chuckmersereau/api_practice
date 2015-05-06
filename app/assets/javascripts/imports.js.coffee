$ ->
  if $('#csv_import_preview')[0]?
    $.ajax
      type: 'GET'
      url: "/imports/" + $.mpdx.import_id + "/csv_preview_partial"
      dataType: "html"
      success: (preview_html) ->
        $("#csv_import_preview").html(preview_html)
