# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$('.category').off 'change'
$('.category').change ->
  $(this).id
  $("#articles_content").html("<%= escape_javascript(render :partial => 'article_categories/categories', locals: { article_categories: @article_categories }  )%> ");
