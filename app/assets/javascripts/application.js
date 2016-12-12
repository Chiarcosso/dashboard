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
//= require_tree .
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.it.js

function domInit() {

  $('.close').off('click');
  $('.close').on('click',function(){
    specificCloseFunctions();
    $(this).parent().remove();
  })

  $('.popup form').submit(function(){
    specificSubmitFunctions()
    $(this).parents('.popup').children('.close:first').trigger('click');
  })

  $('.ajax-link').off('click');
  $('.ajax-link').on('click',function(e){
    alert(this.attr('type')+'we');
  })

  $('.popup-link').off('click');
  $('.popup-link').on('click', function(e){
    var target = $(this).data('target');
    var name = $(this).data('name');
    $.ajaxSetup ({
      'beforeSend': function(xhr){
        xhr.setRequestHeader("Accept", "text/javascript");
      }
    })
    valuesToSubmit = $('form').serialize()
    $.ajax({
        type: "GET",
        url: target,
        data: valuesToSubmit,
        dataType: "script"
    }).ajaxComplete(function(data){
      // $('body').append('<div class="popup" id="'+name+'"></div>');
      alert('popup');

    })
    return false

  })

}
