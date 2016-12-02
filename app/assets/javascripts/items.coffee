# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@init = () ->

  $('#barcode').focus().select()
  $('.remove_item').click () ->
    console.log(this)
    alert(this.id)
    $('#box-'+this.id).remove()

  $(document).off 'keypress'
  $(document).keypress (e) ->
    if $(':focus').attr('id') == 'barcode' && e.which == 13
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
