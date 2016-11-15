# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@init = () ->

  $('#barcode').focus().select();

  $('.category_check').off 'change'
  $('.category_check').change ->
    console.log('changed!')
    $(this).form.submit()

  $(document).off 'keypress'
  $(document).keypress (e) ->
    if $(':focus').attr('type') != 'submit'
      if e.which == 13
        e.preventDefault()
        console.log($(':focus').attr('type'))
        # nx = $(':focus').parent.next.nth-child 2.focus
        nx = $(':focus').parent().next()
        if nx.children('textarea').length > 0
          nx.children('textarea').focus().select()
        if nx.children('input').length > 0
          console.log(nx.children('input').length)
          nx.children('input').focus().select()
        else
          $('#article-submit').focus()
