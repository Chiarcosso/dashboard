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
function reloadSelectBoxes(){
  $('select').each(function(select){
    console.log($('select').html());
  })
}

function domInit() {

  $('.close').off('click');
  $('.close').on('click',function(){
    specificCloseFunctions();
    $(this).parent().remove();
  })

  $('.popup form').submit(function(){
    specificSubmitFunctions();
    // window.setTimeout(function(){
      reloadSelectBoxes();
      $(this).parents('.popup').children('.close:first').trigger('click');
    // },1500);
  })

  $('.hover-hilight').off('click');
  $('.hover-hilight').on('click',function(){
    var route = $(this).data('target');
    alert(route);
    $.ajax({
      method: 'post',
      url: route
    })
  })

  var l = $('.autosearch').val().length;
  $('.autosearch').first()[0].setSelectionRange(l,l);;
  $('.autosearch').first().focus();
  // var lineend = $.Event('keyup');
  // lineend.which = 35;
  // $('.autosearch').first().trigger(lineend);

  var timer;
  $('.autosearch').off('keyup');
  $('.autosearch').on('keyup',function(e){
    var element = this;
    window.clearTimeout(timer);
    if((48 <= e.which && e.which <= 57) || (65 <= e.which && e.which <= 90) || (96 <= e.which && e.which <= 105) || (188 <= e.which && e.which <= 191) || (e.which == 220) || (e.which == 222) || (e.which == 13)) {
      timer = window.setTimeout(function(){
          console.log(e.which);
          $(element).parent('form').submit();
      },1000);
    }
  });


  // $('.autocomplete').off('ready');
  // $('.autocomplete').on('ready',function(){
  //   var context = $(this).data('context');
  //   $(this).autocomplete({
  //             minLength: 2,
  //             source: $(this).data('/ac/'+context),
  //             // This updates the textfield when you move the updown the suggestions list,
  //             // with your keyboard. In our case it will reflect the same value that you see
  //             // in the suggestions which is the person.given_name.
  //             focus: function(event, ui) {
  //                 $(this).val(ui.item.name);
  //                 return false;
  //             },
  //             // Once a value in the drop down list is selected, do the following:
  //             select: function(event, ui) {
  //                 $(this).val(ui.item.name);
  //                 $('#'+context+'_id').val(ui.item.id);
  //                 return false;
  //             }
  //         })
  //         // The below code is straight from the jQuery example. It formats what data is
  //         // displayed in the dropdown box, and can be customized.
  //         .data( "autocomplete" )._renderItem = function( ul, item ) {
  //             return $( "<li></li>" )
  //                 .data( "item.autocomplete", item )
  //                 .append( "<a>" + item.name + "</a>" )
  //                 .appendTo( ul );
  //         };
  // });


  $('.ajax-link').off('click');
  $('.ajax-link').on('click',function(e){
    var target = $(this).data('target');
    var method = $(this).data('method');
    var data = $(this).data('data');
    $.ajax({
        type: "POST",
        url: target,
        // data: valuesToSubmit,
        // dataType: "script"
        complete: function(data){
          console.log(data)
        }
  });

  $('.popup-link').off('click');
  $('.popup-link').on('click', function(e){
    var target = $(this).data('target');
    var name = $(this).data('name');
    // $.ajaxSetup ({
    //   'beforeSend': function(xhr){
    //     xhr.setRequestHeader("Accept", "text/javascript");
    //   }
    // })
    // valuesToSubmit = $('form').serialize()
    $.ajax({
        type: "GET",
        url: target,
        // data: valuesToSubmit,
        // dataType: "script"
        complete: function(data){
           $('body').append('<div class="popup" id="'+name+'"></div>');
           $('#'+name).html(data.responseText);
           $('#'+name).append('<div class="close"><img src="close.png"></div>');
        }
    })

    return false

  })

}
