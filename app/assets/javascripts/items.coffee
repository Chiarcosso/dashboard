# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@init = () ->

  if $('.item_box').length
    $('.item_box:last input:first').select()
  else
    $('#barcode').focus().select()

  $('.remove_item').click () ->
    $('#box-'+this.id).remove()

  $(document).off 'keypress'
  $(document).keypress (e) ->
    # var inputId = $(':focus').attr('id')
    if e.which == 13
      if $(this).is(':last-child')
        $('#barcode').focus().select()
      else if $(':focus').attr('id') == 'barcode'
        $.ajaxSetup ({
          'beforeSend': (xhr) ->
            xhr.setRequestHeader("Accept", "text/javascript")
        })
        valuesToSubmit = $('form').serialize()
        $.ajax({
            type: "POST",
            url: $('form').attr('action'),
            data: valuesToSubmit,
            dataType: "script"
        })
        return false
      else
        $(this).next('input').select()
