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
/*global $ */
//= require jquery
//= require bootstrap
//= require jquery_ujs
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.it.js
//= require jquery-ui
//= require autocomplete-rails
//= require_tree .

jQuery.ajaxSetup({
            // Disable caching of AJAX responses
    cache: false
});


function activateLoadingScreen() {
    "use strict";
    // $('form').on('submit',function() {
    //
    //   if(!$(this).hasClass('no-loader') && $(this).children('.no-loader').length == 0) {
    //     activateLoadingScreen();
    //   }
    // });
    // $('input[type=submit]').on('click',function() {
    //
    //   if(!$(this).hasClass('no-loader')) {
    //     activateLoadingScreen();
    //   }
    // });
    // $('a').on('click',function() {
    //
    //   if(!$(this).hasClass('no-loader') && !$(this).hasClass('dropdown-toggle') ) {
    //     activateLoadingScreen();
    //   }
    // });
    // $('button').on('click',function() {
    //
    //   if(!$(this).hasClass('no-loader')) {
    //     activateLoadingScreen();
    //   }
    // });

    if(!$(this).hasClass('no-loader')){
      $('.loading-screen').show();
    }

}

var leave_page_message = null;
function before_leave_event(e){
  alert('message');
  if(leave_page_message != null){
    if(!confirm(leave_page_message)){
      e.stopPropagation();
      e.preventDefault();

    } else {
      leave_page_message = null;
    }
  } else {
    leave_page_message = null;
  }
  deactivateLoadingScreen();
}



function deactivateLoadingScreen() {
    "use strict";
    $('.loading-screen').hide();
}

function autofocus_ready_func() {
    "use strict";
    $('.autofocus').first().val($('.autofocus').first().val());
    $('.autofocus').first().select().focus();
}

function error_click_func() {
    "use strict";
  //  $('.selected-row').removeClass('selected-row');
    $(this).fadeOut(400, function () { $(this).remove(); });
    deactivateLoadingScreen();
}

function infobox_block_mouseenter_func() {
    "use strict";
    var el, top, left;
    el = $(this).clone();
    $('.infobox-block-expanded').remove();
    if ($(this).data('expand')) {
        $(el).removeClass('infobox-block');
        $(el).addClass('infobox-block-expanded');
        $('body').append(el);
        top = $(this).offset().top + 2;
        left = $(this).offset().left + 2;
        $(el).css('top', top + 'px');
        $(el).css('left', left + 'px');
    }
}

function infobox_block_expanded_mouseleave_func() {
    "use strict";
    $('.infobox-block-expanded').remove();
}

var infobox_name;
function complete_infobox_link_func(data) {
    "use strict";
    $('#' + infobox_name).html(data.responseText);
    // //clearMemory();
}

function infobox_button_click_func() {
    "use strict";
    if(!$(document.activeElement).hasClass('no-infobox-link')){
      if ($(this).parents('.row').hasClass('selectable')) {
          $('.selected-row').removeClass('selected-row');
          $(this).parents('.row').first().addClass('selected-row');
      }
      var target;
      infobox_name = $(this).data('name');
      target = $(this).data('target');
      var method = $(this).data('method');
      var data = $(this).data('data');
      if(method == undefined ){
        method = 'get';
      }
      if ($('#' + infobox_name).length === 0) {
          $('.infobox').remove();
          $('body').append('<div class="infobox" id="' + infobox_name + '"></div>');
          $.ajax({
              method: method,
              url: target,
              data: data,
              complete: complete_infobox_link_func
          });
      } else {
          $('#' + infobox_name).remove();
      }
    }
}

var popup_name;
function complete_popup_link_func(data) {
    "use strict";
    $('.popup #' + popup_name).remove();

    $('body').append('<div class="popup" id="' + popup_name + '"></div>');
    $('#' + popup_name).html(data.responseText);
    $('#' + popup_name).append('<div class="close">Chiudi</div>');
    $('#' + popup_name + ' #autofocus').focus();
    // //clearMemory();
}

function popup_link_func(e) {
    "use strict";
    var method, action, data;
    popup_name = $(this).data('name').replace(' ', '_');

    if (this.nodeName === 'INPUT' && $(this).attr('type') === 'submit') {
        action = $(this).form().attr('action');
        method = $(this).form().attr('method');
        data = $(this).form().serializeArray();
    } else {
        e.preventDefault();
       // activateLoadingScreen();
        if ($(this).data('method') !== undefined) {
            method = $(this).data('method');
        } else {
            method = 'GET';
        }
        action = $(this).data('target');
        if ($(this).data('data') !== undefined) {
            data = $(this).data('data');
        }
    }
    $.ajax({
        type: method,
        url: action,
        data: data,
        complete: complete_popup_link_func
    });
    return false;
}

function changing_checkbox_change_func() {
    "use strict";
    var eqs, class_name, data;
    eqs = [];
    class_name = $(this).data('class');
    $.each($('.' + class_name + ':checked'), function () {
        eqs.push($(this).val());
    });
    data = $('.changing-checkbox').data('data');
    data[class_name] = eqs;
    $('.changing-select').data('data', data);
    $('.changing-checkbox').data('data', data);
}

function changing_select_change_func() {
    "use strict";
    var url, data;
    url = $(this).data('target');
    data = $(this).data('data');
    data[this.id] = $(this).val();
    $.ajax({
        url: url,
        method: 'post',
        data: data
    });
}

function close_click_func() {
    "use strict";
    $('.custom-autocomplete-dropdown').remove();
    specificCloseFunctions();
    $(this).parent().fadeOut(400, function () {$(this).remove(); });
    deactivateLoadingScreen();
}

var ajax_link_element;
function complete_ajax_link_func(data) {
    "use strict";
    var params = JSON.parse(data.responseText);
    $(ajax_link_element).html(params.html);
    deactivateLoadingScreen();
    //clearMemory();
}

function ajax_link_click_func(e) {
    "use strict";
    // if (($(this).data('confirmation')) !== undefined) {
    //     if (!confirm($(this).data('confirmation'))) {
    //         return null;
    //     }
    // }
    if(!$(document.activeElement).hasClass('no-ajax-link')){
      activateLoadingScreen();
      e.preventDefault();
      var target, method, data, complete;
      target = $(this).data('target');
      // var method = $(this).parents('form').first().children('input[name=_method]').val();
      method = $(this).data('method');
      console.log(target,method,$(this).data('data'));
      data = $(this).data('data');

      ajax_link_element = $(this).data('target-element');
      if ($(this).data('check-complete')) {
          complete = complete_ajax_link_func;
      } else {
          complete = null;
      }
      $.ajax({
          type: method,
          url: target,
          data: data,
          complete: complete
      });
    }
}

var json_link_element;
function complete_json_autocomplete_keyup_func(data) {
    "use strict";
    data = JSON.parse(data.responseText);
    var i, j, content;
    $(json_link_element).html('');
    for (i = 0; i < data.length; i += 1) {
        content = '<div class="row colored">';
        for (j = 0; j < data[i].length; j += 1) {
            // $(row).append($('<div class="col-sm-' + data[i][j].width + '">' + data[i][j].value + '</div>'));
            content += '<div class="col-sm-' + data[i][j].width + '">' + data[i][j].value + "</div>\n";
        }
        content += '</div>';
        $(json_link_element).append(content);
    }
    //clearMemory();
}

function json_autocomplete_keyup_func() {
    "use strict";
    json_link_element = $(this).data('target-element');
    $.ajax({
        url: $(this).data('target'),
        method: 'post',
        data: {search: $(this).val()},
        complete: complete_json_autocomplete_keyup_func
    });
}

function selectable_click_func() {
    "use strict";
    $('.sbox').hide();
    $('.selected-row').removeClass('selected-row');
    $(this).addClass('selected-row');
    $($(this).data('sbox')).show();
}

var popup_link_name;
function complete_popup_link_func(data) {
    "use strict";
     $('body').append('<div class="popup" id="'+popup_link_name+'"></div>');
     $('#'+popup_link_name).html(data.responseText);
     $('#'+popup_link_name).append('<div class="close">Chiudi</div>');
     // activateClose();
     deactivateLoadingScreen();
     //clearMemory();
}

function popup_link_click_func() {
    "use strict";
    activateLoadingScreen();
    var target, method, data;
    target = $(this).data('target');
    data = $(this).data('data');
    method = $(this).data('method');
    if (method === undefined) {
      method = 'get';
    }
    popup_link_name = $(this).data('name');
    // alert(popup_link_name);
    $.ajax({
        type: method,
        url: target,
        data: data,
        complete: complete_popup_link_click_func
    });

    return false;

}

function clickable_link_click_func() {
    "use strict";
    target = $(this).data('target');
    method = $(this).data('method');
}

function on_top_click_func(e) {
  "use strinct";
  e.stopPropagation();
}

function toggable_display_change_func() {
  "use strinct";
  $('#'+$(this).data('target')).removeClass('invisible').addClass('visible');
}

function check_box_parent_click_func(){
  "use strict";
  console.log($(this));
  $(this).children('input[type=checkbox]').val(!$(this).children('input[type=checkbox]').val());
}

function nocr_keyup_func(e){
  if(e.which == 13){
    e.preventDefault();
    e.stopPropagation();
  }
}

var line;
var scroll_element;
function complete_ajax_update_change_func() {
  "use strict";
  $('#'+scroll_element[0].id).scrollTop(line);
}

function ajax_update_change_func() {
  "use strict";
  var target = $(this).data('target');
  var data = {value: $(this).val(), field: $(this).attr('name'), additional: $(this).data('additional'), tab: $(this).data('tab'), station: $(this).data('station')};
  scroll_element = $(this).parents('.scrollable-panel').first();
  line = $(scroll_element).scrollTop();
  $.ajax({
      type: 'post',
      url: target,
      data: data,
      complete: complete_ajax_update_change_func
  });
}

function clickbox_click_func() {
  "use strict";
  activateJS();
  console.log($('#'+$(this).data('trigger')));
  $(this).css('background-color: red;');
  // $('#'+$(this).data('trigger')).trigger('click');
  // $(this).children('#'+$(this).data('trigger')).trigger('click');
}

function loading_screen_click_func(){
  activateLoadingScreen();
}

function form_submit_func(event){
  "use strict";
  // console.log($(document.activeElement))
  if(!$(document.activeElement).hasClass('no-loader')){
    activateLoadingScreen();
  }

}

function click_to_submit_click_func(){
  "use strict";
  $(this).closest('form').submit();
  activateLoadingScreen();
}

function data_confirmation_click_func(event){
  if(!confirm($(this).data('confirmation'))){
    setTimeout(deactivateLoadingScreen,200);
    event.preventDefault();
    event.stopPropagation();
  }
}

var new_elements = {};
function create_popup_click_func() {
    "use strict";
    var popup_link_name = $(this).data('popup_id');
     $('body').append('<div class="popup" id="'+popup_link_name+'"></div>');
     $('#'+popup_link_name).html($(this).data('html'));
     $('#'+popup_link_name).append('<div class="close">Chiudi</div>');

     //if are there elements to update in the popup in the future put them in new_elements
     if(!($(this).data('new-elements') == undefined)){
       var ne = $(this).data('new-elements');
       var c = ne.length;

       for(var i = 0; i < c; i++){
         new_elements[ne[i]] = $(ne[i]);
       }

     }

     deactivateLoadingScreen();
     $('#'+popup_link_name+' #focus_element').focus();
}

function toggle_click_func() {
  $($(this).data('target')).toggle();
}

function data_alt_mouseenter_func(){
  "use strict";
  $('.cst-alt').remove();
  var el = $('<div class="cst-alt" style="position: absolute; background-color: #ffc; white-space: nowrap; top: -1.7em; left 2em; z-index: 2500; border: 1px solid black; padding: .2em;">'+$(this).data('alt')+'</div>');
  $(this).append(el);
}

function data_alt_mouseleave_func(){
  "use strict";
  $('.cst-alt').remove();
}

function remember_scroll_form_submit_func(e){
    "use strict";

    $('<input>').attr({
      type: 'hidden',
      name: 'scroll',
      value: $($(this).data('scroll-element')).first().scrollTop()
    }).appendTo(this);
    $('<input>').attr({
      type: 'hidden',
      name: 'scroll_element',
      value: $(this).data('scroll-element')
    }).appendTo(this);

}

function move_under_loader_func(){
  "use strict";
  var zindex = $('.loading-screen').css('z-index');
  $(this).parents('.popup').first().css('z-index',zindex-1);

}

function xbox_click_func(){
  "use strict";
  if ($(this).hasClass('no-ajax')){
    return;
  }
  var route = $(this).data('route');
  var data = $(this).data('data');
  var xbox = $(this).data('xbox');
  $.ajax({
    url: route,
    data: data,
    type: 'post',
    complete: function(response){
      $('.sbox').hide();
      $(xbox).show();
      $(xbox).html(response.responseText);
    }
  });
}

function activateJS() {
    "use strict";

    $('document').unbind();

    $('body').off("click").off("mouseenter").off("mouseleave").off("change").off("keyup");

    $('#center').on('load', '.autofocus', autofocus_ready_func);

    $('body').on('click', '[data-confirmation]', data_confirmation_click_func);

    $('body').on("click", ".error", error_click_func);

    $('body').on("mouseenter", ".infobox-block", infobox_block_mouseenter_func);

    $('body').on("mouseleave", ".infobox-block-expanded", infobox_block_expanded_mouseleave_func);

    $('body').on('click', '.infobox-button', infobox_button_click_func);

    $('body').on('change', '.changing-checkbox', changing_checkbox_change_func);

    $('body').on('change', '.changing-select,.changing-checkbox', changing_select_change_func);

    $('body').on('click', '.close', close_click_func);

    $('body').on('click', '.popup-link', popup_link_func);

    $('body').on('click', '.ajax-link', ajax_link_click_func);

    $('body').on('keyup', '.json-autocomplete', json_autocomplete_keyup_func);

    $('body').on('click', '.selectable', selectable_click_func);

    $('body').on('click', '.clickable-link', clickable_link_click_func);

    $('body').on('click', '.on-top', on_top_click_func);

    $('body').on('change', '.toggable-display-fld', toggable_display_change_func);

    $('body').on('keyup', '.toggable-display-fld', toggable_display_change_func);

    $('body').on('click', 'div > input[type=checkbox]', check_box_parent_click_func);

    $('body').on('keypress', '.prevent-cr', nocr_keyup_func);

    $('body').on('keyup', '.no-cr', nocr_keyup_func);

    $('body').on('change', '.ajax_update', ajax_update_change_func);

    $('body').on('click', '.clickbox', clickbox_click_func);

    $('body').on('click', '.loading_screen', loading_screen_click_func);

    $('body').on('click', '.click-to-submit', click_to_submit_click_func);

    $('body').on('change', '.submitting-select', click_to_submit_click_func);

    $('body').on('submit', 'form', form_submit_func);

    $('body').on('click', '.create_popup', create_popup_click_func);

    $('body').on('click', '.toggle', toggle_click_func);

    $('body').on('mouseenter', '[data-alt]', data_alt_mouseenter_func);

    $('body').on('mouseleave', '[data-alt]', data_alt_mouseleave_func);

    $('body').on('submit','.remember_scroll_form', remember_scroll_form_submit_func);

    $('body').on('submit','.popup form', move_under_loader_func);

    $('body').on('click','.xbox', xbox_click_func);

}

function clearMemory() {
    // "use strict";
    // jQuery('*').unbind();
    // activateJS();
}

// function activateErrors() {
//     "use strict";
//     // $('.error').delay(3000).fadeOut();
// }
function seconds_to_clock(tm){
  return ('0'+Math.floor(tm/3600)).slice(-2)+':'+('0'+Math.floor((tm/60)%60)).slice(-2)+':'+('0'+(tm%60)).slice(-2);
}

function activateCustomAutocomplete(func) {
    "use strict";
    $('.custom_autocomplete').off('keyup');
    $('.custom_autocomplete').on('keyup', function(e) {
    var focusElement;
    if(e.which == 13) {
      e.preventDefault();
      return;
    }
    if(e.which == 40) {
      focusElement = $('.custom-autocomplete-choice').first();
      focusElement.addClass('custom-autocomplete-choice-selected');
      $(focusElement).attr('tabindex',-1).focus();
      return;
    }
    var element = this
    var search = this.value;
    var route = $(this).data('route');
    var target = $(this).data('target');
    $.ajax({
      url: route,
      method: 'post',
      data: { 'search': search },
      success: function(data){
        var offset = $(element).offset();
        offset.top += $(element).outerHeight();
        $('.dropdown_original').removeClass('dropdown_original');
        $(element).addClass('dropdown_original');
        $('.custom-autocomplete-dropdown').remove();
        $('body').append('<div class="custom-autocomplete-dropdown" style="top: '+offset.top+'px; left: '+offset.left+'px; width: '+$(element).outerWidth()+'px;"></div>');
        $.each(data,function(){
          var dt = ''
          $.each(this,function(k,v){
            dt += 'data-'+k+'="'+v+'" ';
          })
          $('.custom-autocomplete-dropdown').first().append('<div class="form-control custom-autocomplete-choice" '+dt+'>'+this.label+'</div>')
        });
        $('.custom-autocomplete-choice').off('keyup');
        $('.custom-autocomplete-choice').on('keyup',function (e){
          var focusElement = $(this);
          switch(e.which){
            case 40: if ($(this).next('.custom-autocomplete-choice').length > 0){
                        $(focusElement).removeClass('custom-autocomplete-choice-selected');
                        focusElement = $(this).next('.custom-autocomplete-choice');
                        $(focusElement).addClass('custom-autocomplete-choice-selected');
                        $(focusElement).attr('tabindex',-1).focus();
                      }
                     break;
            case 38: if ($(this).prev('.custom-autocomplete-choice').length > 0){
                         $(focusElement).removeClass('custom-autocomplete-choice-selected');
                         focusElement = $(this).prev('.custom-autocomplete-choice');
                         $(focusElement).addClass('custom-autocomplete-choice-selected');
                         $(focusElement).attr('tabindex',-1).focus();
                      } else {
                        focusElement = $('.dropdown_original').first();
                        $(focusElement).focus();
                        $(focusElement).val($(focusElement).val());
                        console.log($(focusElement));
                      }
                     break;
            case 13: $(focusElement).trigger('click');
                     break;
          }

        });
        $('.custom-autocomplete-choice').off('click');
        $('.custom-autocomplete-choice').on('click',function (){
          var choice = func(this);
          $(element).val(choice['label']);
          $.each($('input.'+target+'-'+choice['field']),function(){
            $(this).val('');
          });
          $.each($('.ac-'+target+'-'+choice['field']),function(){
            if (!$(this).attr('name').includes('[]')){
              $(this).remove();
            } else {
              alert($(this).attr('name'))
            }
          });
          $.each(choice,function(key,val){
            if (key != 'label' && key != 'field' && key != 'id') {
              if ($('input[name="'+target+'['+key+']"]').size() > 0 && !key.includes('[]')) {
                $('input[name="'+target+'['+key+']"]').val(val);
              } else {
                if(key.includes('[]')){
                  var arrayElement = $('<div data-target="'+target+'" class="autocomplete-field ac-'+target+'-array-'+choice['field']+'"></div>');
                  arrayElement.append('<div class="row colored"><div class="col-sm-9">'+choice['label']+'</div><div class="col-sm-3"></div>');
                  arrayElement.children('.row,.col-sm-9').first().append('<input type="hidden" data-target="'+target+'" class="autocomplete-field ac-'+target+'-array-'+choice['field']+'" name="'+target+'['+key+']" value="'+val+'"/>');
                  arrayElement.children('.row,.col-sm-3').first().append('<button data-target="'+target+'" class="autocomplete-field ac-'+target+'-array-'+choice['field']+'" onclick="$(this).parent().parent().remove()">X</button>');
                  $(element).parent().append(arrayElement);
                } else {
                  $(element).parent().append('<input type="hidden" data-target="'+target+'" class="autocomplete-field ac-'+target+'-'+choice['field']+'" name="'+target+'['+key+']" value="'+val+'"/>');
                }

              }
            }
          });
          $('.custom-autocomplete-dropdown').remove();
        });
      },
      error: function(data){
        console.log('Autocomplete error',data);
      }
    });
  });
}

function activateHideBlock() {
  $('.hide-block').off('click');
  $('.hide-block').on('click',function(){
    element = $(this).data('block');
    $(element).toggle(this.checked);
  });
}

function activatePopUp() {
  $('.popup-link').off('click');
  $('.popup-link').on('click', function(e){
    if(this.nodeName == 'INPUT' && $(this).attr('type') == 'submit'){
      deactivateLoadingScreen();
      action = $(this).form().attr('action');
      method = $(this).form().attr('method');
      data = $(this).form().serializeArray();
      name = $(this).data('name').replace(' ','_');
      $.ajax({
          type: method,
          url: action,
          data: data,
          complete: function(data){
             $('.popup#'+name).remove();
             $('body').append('<div class="popup" id="'+name+'"></div>');
             $('#'+name).html(data.responseText);
             $('#'+name).append('<div class="close">Chiudi</div>');
             // activateClose();
             deactivateLoadingScreen();
          }
      });
    } else {
      e.preventDefault();
      activateLoadingScreen();
      var target = $(this).data('target');
      var name = $(this).data('name').replace(' ','_');
      $.ajax({
          type: "GET",
          url: target,
          complete: function(data){
             $('.popup#'+name).remove();
             $('body').append('<div class="popup" id="'+name+'"></div>');
             $('#'+name).html(data.responseText);
             $('#'+name).append('<div class="close">Chiudi</div>');
             // activateClose();
             deactivateLoadingScreen();
          }
      });
    }
    return false;
  });
}

function activateGallery() {
  $('.gallery-image').off('click');
  $('.gallery-image').on('click',function(){
    $('body').append('<div class="popup gallery-popup" id="gallery"><div class="close">Chiudi</div><div class="scrollable-panel"><img src="'+this.src+'" class="gimage gi-rotate-0"/></div></div>');
    var move = false
    var offsetX = 0;
    var offsetY = 0;
    $('.gimage').on('mousedown',function(e){
      offsetX = e['pageX']
      offsetY = e['pageY']
      move = true;
      // moved = false;
    });
    $('.gimage').on('mouseup',function(e){
      move = false;
    });
    $('.gimage').on('contextmenu',function(e){
      // if(!moved){

        e.preventDefault();
        if($(this).hasClass('gi-rotate-0')){
          $(this).removeClass('gi-rotate-0');
          $(this).addClass('gi-rotate-90');
        } else if($(this).hasClass('gi-rotate-90')){
          $(this).removeClass('gi-rotate-90');
          $(this).addClass('gi-rotate-180');
        } else if($(this).hasClass('gi-rotate-180')){
          $(this).removeClass('gi-rotate-180');
          $(this).addClass('gi-rotate-270');
        } else if($(this).hasClass('gi-rotate-270')){
          $(this).removeClass('gi-rotate-270');
          $(this).addClass('gi-rotate-0');
        }
      // }
      // move = false;
    });

    // $('.gimage').on('mouseup',function(e){
    //   if(!moved){
    //     if($(this).hasClass('gi-rotate-0')){
    //       $(this).removeClass('gi-rotate-0');
    //       $(this).addClass('gi-rotate-90');
    //     } else if($(this).hasClass('gi-rotate-90')){
    //       $(this).removeClass('gi-rotate-90');
    //       $(this).addClass('gi-rotate-180');
    //     } else if($(this).hasClass('gi-rotate-180')){
    //       $(this).removeClass('gi-rotate-180');
    //       $(this).addClass('gi-rotate-270');
    //     } else if($(this).hasClass('gi-rotate-270')){
    //       $(this).removeClass('gi-rotate-270');
    //       $(this).addClass('gi-rotate-0');
    //     }
    //   }
    //   move = false;
    // });
    $('.gimage').on('mousemove',function(e) {
      if(move){
        spaceX = offsetX - e['pageX'];
        spaceY = offsetY - e['pageY'];
        $(this).offset({top: $(this).offset()['top'] - spaceY, left: $(this).offset()['left'] - spaceX});
        offsetX = e['pageX'];
        offsetY = e['pageY'];
        // moved = true;
      }
    });

    $('.gimage').on('dragstart',function(e){
      e.preventDefault();
    });
    // activateClose();
  });
}



function reloadSelectBoxes() {
  $('select').each(function(select){
    console.log($('select').html());
  });
};

// function activateClose() {
//   $('.close').off('click');
//   $('.close').on('click',function(){
//     $('.custom-autocomplete-dropdown').remove();
//     specificCloseFunctions();
//     $(this).parent().fadeOut().remove();
//     deactivateLoadingScreen();
//   });
// };

function activateReserveAlert() {
  if($('.signal-danger').length > 0){
    $.each($('.signal-danger'),function(){
      alert($(this).data('name')+' è sotto la scorta minima.');
    });
  }
}

function activateFinder() {
  $('.finder').off();
  $('.finder').on('keyup',function(e){
    var target = $(this).data('target')+$(this).val();
    e.preventDefault();
    if (e.which == 13){
      activateLoadingScreen();
      $.ajax({
        url: target,
        method: 'post'
      });
    }
  });
}

function activateDelete() {
  $('.delete').off('click');
  $('.delete').on('click',function(e){
    e.preventDefault();
    var object = $(this).data('object');
    var target = $(this).data('target');
    var id = $(this).data('id');
    if(confirm('Conferma eliminazione '+object+' nr. '+id)){
      activateLoadingScreen();
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

function activateAF() {
  // $('.autofocus').first().focus();
  // // $('.autofocus').val('');
  // $('.autofocus').first().select();
};

function activateDatePicker(date) {
  if(typeof date == null){
    dt = new Date();
  } else {
    dt = new Date(date.substring(0,3),date.substring(4,6),date.substring(7,9));
  }

  $('[data-behavior=datepicker]').datepicker({
    language: "it",
    autoclose: true,
    todayHighlight: true,
  //  setValue: ($(this).data('no-default')=='true'?'':dt)
  });

};



function activateAutoComplete() {
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

  // activateClose();
  activateAF();
  activateDelete();
  $('.popup form').submit(function() {
    specificSubmitFunctions();
      reloadSelectBoxes();
      $(this).parents('.popup').children('.close:first').trigger('click');
  });

  activateLoadingScreen();

  $('.cr-field').on('keypress');
  $('.cr-field').on('keypress',function(e){
    if ($(':focus').attr('type') != 'submit'){

      if (e.which == 13){
        e.preventDefault();
        // console.log($(':focus').attr('type'))
        // nx = $(':focus').parent.next.nth-child 2.focus
        nx = $(':focus').parent().next().children('.cr-field').first();
        switch($(nx).prop('nodeName')){
          case 'TEXTAREA':
          case 'INPUT':
          case 'SELECT': $(nx).focus().select();
            break;
          default: $('#article-submit').first().focus();
        }
        // if ($(nx).children('textarea').length > 0){
        //   $(nx).children('textarea').focus().select();}
        // if ($(nx).children('input').length > 0){
        //   $(nx).children('input').focus().select();}
        // if ($(nx).children('select').length > 0){
        //   $(nx).children('select').first().focus().select();}
        // else{


      }
    }
  });

  // $('.on-top').off('click');
  // $('.on-top').on('click',function(e) {
  //   e.stopPropagation();
  // });

  $('.hover-hilight').off('click');
  $('.hover-hilight').on('click',function(e) {
    if ($(this).hasClass('clickable')) {
      var itemRow = $(this);

      if ($(this).data('popup') == true) {
        //$('body').append('<div class="popup">Quantità <input type="number" value="1" step="any" pattern="[0-9]+([\\.,][0-9]+)?" formnovalidate="true" id="amount" name="amount" class="form-control"><div class="close">Chiudi</div></div>');
        $('body').append('<div class="popup">Quantità <input type="text" pattern="[0-9]+([\\.,][0-9]+)?" id="amount" name="amount" data-max="'+$(this).data('max')+'" class="input-number form-control"><div class="close">Chiudi</div></div>');
        $('#amount').val('1');
        $('.popup').css({height: '10em'});
        // activateClose();

        $('#amount').focus();
        $('#amount').off('keypress');
        $('#amount').on('keypress',function(e) {
          if(e.which == '13'){
            $('.popup').remove();
            // itemRow.find('#chamount').val($(this).val());
            $('#chamount').val($(this).val().replace(',','.'));
            if (parseFloat($('#chamount').val()) > parseFloat($(this).data('max'))){
              $('#chamount').val($(this).data('max'));
            }
            var route = itemRow.data('target');
            itemRow.parents('form').first().append('<input type=hidden name="item" value="'+itemRow.data('data')+'">')
            itemRow.parents('form').first().append('<input type=hidden name="model" value="'+itemRow.data('model')+'">')

            var valuesToSubmit = itemRow.parents('form').first().serialize();
            activateLoadingScreen();
            $.ajax({
              method: 'post',
              url: route,
              data: valuesToSubmit
            });
          }
        });
      } else {
        var route = $(this).data('target');
        $(this).parents('form').first().append('<input type=hidden name="item" value="'+$(this).data('data')+'">');
        itemRow.parents('form').first().append('<input type=hidden name="model" value="'+itemRow.data('model')+'">')
        var valuesToSubmit = $(this).parents('form').first().serialize();
        activateLoadingScreen();
        $.ajax({
          method: 'post',
          url: route,
          data: valuesToSubmit
        });
      }
    }
  });

  if($('.autosearch').length > 0) {
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
  $('.autosearch').on('keyup',function(e) {
    var element = this;
    var form = $(this).parents('form').first();
    // window.clearTimeout(timer);
    if(/*(48 <= e.which && e.which <= 57) || (65 <= e.which && e.which <= 90) || (96 <= e.which && e.which <= 105) || (188 <= e.which && e.which <= 191) || (e.which == 220) || (e.which == 222) ||*/ (e.which == 13)/* || (e.which == 8) || (e.which == 46)*/) {
      // timer = window.setTimeout(function(){
          form.append('<input type="hidden" id="no-commit" name="no-commit" value="no-commit">');
          // $(element).parent('form').submit();
          activateLoadingScreen();
          var valuesToSubmit = form.serialize();
          var route = form.attr('action');
          var method = form.attr('method');
          $.ajax({
            method: method,
            url: route,
            data: valuesToSubmit
          });
      // },1000);
    }
  });


  activateAutoComplete();

  $('.chklist').off('click');
  $('.chklist').on('click',function(){
    alert('oo');
    msg = $(this).data('dsc');
    sr = $(this).data('serial');
    if(sr != ''){
      msg += ' ('+sr+')';
    }
    if(confirm("Rimuovere "+msg+"?")){
      $(this).remove();
      var e = $.Event('keyup');
      e.which = 13;
      $('input[name=search]').trigger(e);
    }
  });

  $('.ajax-link-select').off('change');
  $('.ajax-link-select').on('change',function(e) {
    activateLoadingScreen();
    e.preventDefault();
    var form = $(this).parents('form').first()[0];
    var target = form.action;
    var method = form.method;
    var data = $(form).serializeArray();
    $.ajax({
        type: method,
        url: target,
        data: data,
        complete: function(data){
          console.log(data);

        }
      });
  });

  $('.ajax-link-stand-alone').off('click');
  $('.ajax-link-stand-alone').on('click',function(e) {
    e.preventDefault();
    e.stopPropagation();
    var route = $(this).data('route');
    var method = $(this).data('method');
    var data = $(this).data('data');
    var label = $(this).data('label');
    if(confirm('Eliminare '+label)){
      activateLoadingScreen();
      $.ajax({
          type: method,
          url: route,
          data: data,
          complete: function(data){
            console.log(data);
          }
        });
    }

  });

  // $('.popup-link').off('click');
  // $('.popup-link').on('click', function(e) {
    deactivateLoadingScreen();
    // }
};
