// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require bootstrap
//= require jquery_ujs
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.it.js
//= require jquery-ui
//= require autocomplete-rails
//= require_tree .

function reloadSelectBoxes(){
  $('select').each(function(select){
    console.log($('select').html());
  });
};

function activateClose(){
  $('.close').off('click');
  $('.close').on('click',function(){
    specificCloseFunctions();
    $(this).parent().remove();
  });
};

function activateDelete(){
  $('.delete').off('click');
  $('.delete').on('click',function(e){
    e.preventDefault();
    var object = $(this).data('object');
    var target = $(this).data('target');
    var id = $(this).data('id');
    alert(object,target,id);
    if(confirm('Conferma eliminazione '+object+' nr. '+id)){
      $.ajax({
        url: target,
        method: 'delete',
        complete: function(data){
          console.log(data);
        }
      });
      $("div[data-target='/output_order/exit/"+id+"']").remove();
      $('.close').first().trigger('click');
    }
  });
};

function activateAF(){
  $('.autofocus').first().focus();
  $('.autofocus').val('');
  // $('.autofocus').first().select();
};

function activateDatePicker(){

  $('[data-behavior=datepicker]').datepicker({
    language: "it",
    autoclose: true,
    todayHighlight: true,
    setValue: ($(this).data('no-default')=='true'?'':today())
  });

};

function preventCr(){
  $('.prevent-cr').on('keypress', function(e){
    if(e.which == 13){
      e.preventDefault();
    }
  })
};

function activateAutoComplete(){
  $('.autocomplete').off('ready');
  $('.autocomplete').on('ready',function(){
    var context = $(this).data('context');
    $(this).autocomplete({
              minLength: 2,
              source: $(this).data('/ac/'+context),
              // This updates the textfield when you move the updown the suggestions list,
              // with your keyboard. In our case it will reflect the same value that you see
              // in the suggestions which is the person.given_name.
              focus: function(event, ui) {
                  $(this).val(ui.item.name);
                  return false;
              },
              // Once a value in the drop down list is selected, do the following:
              select: function(event, ui) {
                  $(this).val(ui.item.name);
                  $('#'+context+'_id').val(ui.item.id);
                  return false;
              }
          })
          // The below code is straight from the jQuery example. It formats what data is
          // displayed in the dropdown box, and can be customized.
          .data( "autocomplete" )._renderItem = function( ul, item ) {
              return $( "<li></li>" )
                  .data( "item.autocomplete", item )
                  .append( "<a>" + item.name + "</a>" )
                  .appendTo( ul );
          };
  });
};

function domInit() {

  activateClose();
  activateAF();
  activateDelete();

  $('.popup form').submit(function(){
    specificSubmitFunctions();;
      reloadSelectBoxes();
      $(this).parents('.popup').children('.close:first').trigger('click');
  });

  $('.hover-hilight').off('click');
  $('.hover-hilight').on('click',function(){
    var route = $(this).data('target');
    $(this).parents('form').first().append('<input type=hidden name="item" value="'+$(this).data('data')+'">')
    var valuesToSubmit = $(this).parents('form').first().serialize();
    $.ajax({
      method: 'post',
      url: route,
      data: valuesToSubmit
    });
  });

  if($('.autosearch').length > 0){
    var l = $('.autosearch').val().length;
    $('.autosearch').first()[0].setSelectionRange(l,l);
    $('.autosearch').first().focus();
  }

  var timer;
  // var no_commit = false;
  // $('input[name=commit]').off('click');
  // $('input[name=commit]').on('click',function(e){
  //   // e.preventDefault();
  //
  //   if (no_commit){
  //     alert('asd');
  //     $('#no-commit').remove();
  //   }
  //
  //   $(this).parent('form').submit();
  // });

  $('.autosearch').off('keyup');
  $('.autosearch').on('keyup',function(e){
    var element = this;
    window.clearTimeout(timer);
    if((48 <= e.which && e.which <= 57) || (65 <= e.which && e.which <= 90) || (96 <= e.which && e.which <= 105) || (188 <= e.which && e.which <= 191) || (e.which == 220) || (e.which == 222) || (e.which == 13) || (e.which == 8) || (e.which == 46)) {
      timer = window.setTimeout(function(){
          $(element).parents('form').first().append('<input type="hidden" id="no-commit" name="no-commit" value="no-commit"');
          // $(element).parent('form').submit();

          var valuesToSubmit = $(this).parents('form').first().serialize();
          var route = $(this).data('target');
          console.log(valuesToSubmit);
          alert();
          $.ajax({
            method: 'post',
            url: route,
            data: valuesToSubmit
          });
      },1000);
    }
  });


  activateAutoComplete();

  $('.ajax-link').off('click');
  $('.ajax-link').on('click',function(e){
    preventDefault();
    var target = $(this).data('target');
    var method = $(this).parents('form').first().children('input[name=_method]').val();
    var data = $(this).data('data');
    alert(method);
    $.ajax({
        type: method,
        url: target,
        complete: function(data){
          console.log(data);
        }
      });
  });

  $('.popup-link').off('click');
  $('.popup-link').on('click', function(e){
    var target = $(this).data('target');
    var name = $(this).data('name');
    $.ajax({
        type: "GET",
        url: target,
        complete: function(data){
           $('body').append('<div class="popup" id="'+name+'"></div>');
           $('#'+name).html(data.responseText);
           $('#'+name).append('<div class="close">Chiudi</div>');
           activateClose();
        }
    });

    return false;

  });

};
