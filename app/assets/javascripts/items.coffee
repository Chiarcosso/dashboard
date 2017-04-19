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
    len = $('#items-container').children().length*200;
    $('#items-container').animate({ scrollTop: len}, 1000)
    $('.item_box:last input:first').select()
  else
    $('input[type=text]').first().focus()

  $('.remove_item').click () ->
    $('#box-'+this.id).remove()


  $('.autofocus-store').first().focus()

  $(document).off 'keypress'
  $(document).keypress (e) ->
    if e.which == 13
      form = $(':focus').parents('form').first()
      if $(':focus').attr('id') == 'store-row'
        if @barcodePtr == undefined
          if $('[data-id='+$(':focus').val()+']').length > 0
            $('[data-id='+$(':focus').val()+']').addClass('selected-item')
            @barcodePtr = $(':focus').val()
            $('.autofocus-store').first().val('')
            $('.autofocus-store').first().attr('placeholder','Scansionare la posizione')
            $('.autofocus-store').first().focus()
        else
          $('[data-id='+@barcodePtr+']').removeClass('selected-item')
          $('[data-id='+@barcodePtr+'] input[type=text]').val($(':focus').val())
          form = $('[data-id='+@barcodePtr+'] form')
          $.ajaxSetup ({
            'beforeSend': (xhr) ->
              xhr.setRequestHeader("Accept", "text/javascript")
          })
          valuesToSubmit = form.serialize()
          $.ajax({
              type: "POST",
              url: form.attr('action'),
              data: valuesToSubmit,
              dataType: "script",
              complete: (data) ->
                console.log('complete:',data.responseText)
                response = data.responseText.split(' ')
                if(response[0] == 'Ok')
                  $('[data-id='+response[1]+']').addClass('positioned-item')
                  $('[data-id='+response[1]+']').remove()
                  console.log($('.store-box').length)
                  if($('.store-box').length == 0)
                    $('.close').trigger('click')
                else
                  $('#'+@barcodePtr).addClass('error-item')
                  alert(data.responseText)


          })
          $('.autofocus-store').first().val('')
          $('.autofocus-store').first().attr('placeholder',"Scansionare l'articolo")
          $('.autofocus-store').first().focus()
          @barcodePtr = undefined

        return false

      else if $(':focus').attr('id') == 'barcode-items'
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
