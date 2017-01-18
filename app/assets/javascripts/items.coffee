# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@specificCloseFunctions = () ->
  $('.item_box:last .remove_item').trigger('click')

@specificSubmitFunctions = () ->
  val = $('#new_article #barcode-articles').val()
  setTimeout ( ->
      e = $.Event('keypress')
      e.which = 13
      $('#dyn_ddt #barcode-items').val(val)
      $('#dyn_ddt #barcode-items').focus().trigger(e)
    ),800

@init = () ->

  if $('.item_box').length
    $('.item_box:last input:first').select()
    $('#items-container').animate({ scrollTop: $('#items-container').height()}, 1000);
  else
    # $('#barcode').focus().select()
    $('input[type=text]').first().focus()

  $('.remove_item').click () ->
    $('#box-'+this.id).remove()


  $(document).off 'keypress'
  $(document).keypress (e) ->
    if e.which == 13
      form = $(':focus').parents('form').first()
      if $(':focus').attr('id') == 'barcode-items'
        $.ajaxSetup ({
          'beforeSend': (xhr) ->
            xhr.setRequestHeader("Accept", "text/javascript")
        })
        valuesToSubmit = form.serialize()
        $.ajax({
            type: "POST",
            url: form.attr('action'),
            data: valuesToSubmit,
            dataType: "script"
        })
        return false
      else if $(':focus').parent().is(':last-child')
        e.preventDefault()
        $('#barcode-items').focus().select()
      else
        e.preventDefault()

        if $(':focus').parent().next().children('input[type!=hidden]').length
          next = $(':focus').parent().next().children('input')
        else
          next = $(':focus').parent().next().children('select')

        next.focus().select()
