# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
@init = () ->

  $('#barcode-articles').focus().select()

  $('.cr-field').off 'keypress'
  $('.cr-field').keypress (e) ->
    if $(':focus').attr('type') != 'submit'
      if e.which == 13
        e.preventDefault()
        # console.log($(':focus').attr('type'))
        # nx = $(':focus').parent.next.nth-child 2.focus
        nx = $(':focus').parent().next()
        if nx.children('textarea').length > 0
          nx.children('textarea').focus().select()
        if nx.children('input').length > 0
          nx.children('input').focus().select()
        if nx.children('select').length > 0
          nx.children('select').first().focus().select()
        else
          $('#article-submit').focus()

@initCategories = () ->

  $('.category_check').off 'change'
  $('.category_check').change ->
    $('.'+this.classList[1]).attr('checked',this.checked)
    $(this).closest('form').submit()
