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
function autofocus_ready_func(){
  $('.autofocus').first().val($('.autofocus').first().val());
  $('.autofocus').first().select().focus();
}

function error_click_func(event){
  $('.selected-row').removeClass('selected-row');
  $(this).fadeOut(400,function(){$(this).remove()});
  deactivateLoadingScreen();
}

function infobox_block_mouseenter_func(){
  el = $(this).clone();
  $(el).removeClass('infobox-block');
  $(el).addClass('infobox-block-expanded');
  $(this).parent().append(el);
  $(el).css('top',$(this).position().top+'px');
  $(el).css('left',$(this).position().left+'px');
}

function infobox_block_expanded_mouseleave_func(){
  $('.infobox-block-expanded').remove();
}

function complete_infobox_link_func(data){
  $('#'+name).html(data.responseText);
}

function infobox_button_click_func(){
  $('.selected-row').removeClass('selected-row');
  $(this).parents('.row').first().addClass('selected-row');
  console.log($(this),$(this).parents('.row').first());
  name = $(this).data('name');
  target = $(this).data('target');
  if($('#'+name).length == 0 ){
    $('.infobox').remove();
    $('body').append('<div class="infobox" id="'+name+'"></div>');
    $.ajax({
      method: 'GET',
      url: target,
      complete: complete_infobox_link_func
    });
  } else {
    $('#'+name).remove();
  }
}

function complete_popup_link_func(data){
   $('.popup#'+name).remove();
   $('body').append('<div class="popup" id="'+name+'"></div>');
   $('#'+name).html(data.responseText);
   $('#'+name).append('<div class="close">Chiudi</div>');
 }

 function popup_link_func(e){
   if(this.nodeName == 'INPUT' && $(this).attr('type') == 'submit'){
     action = $(this).form().attr('action');
     method = $(this).form().attr('method');
     data = $(this).form().serializeArray();
     name = $(this).data('name').replace(' ','_');
   } else {
     e.preventDefault();
     // activateLoadingScreen();
     if (typeof $(this).data('method') != undefined){
       method = $(this).data('method');
     } else {
       method = 'GET';
     }
     action = $(this).data('target');
     name = $(this).data('name').replace(' ','_');
     if (typeof $(this).data('data') != undefined){
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



function activateJS(){

  $('#center').on('load', '.autofocus',autofocus_ready_func);

  $('body').on("click",".error,.infobox", error_click_func);

  $('body').on("mouseenter",".infobox-block", infobox_block_mouseenter_func);

  $('body').on("mouseleave",".infobox-block-expanded", infobox_block_expanded_mouseleave_func);

  $('body').on('click', '.infobox-button', infobox_button_click_func);

  function changing_select_change_func(){
      url = $(this).data('target');
      data = $(this).data('data');
      data[this.id] = $(this).val();
      $.ajax({
        url: url,
        method: 'post',
        data: data
      });
  }

  $('body').on('change','.changing-select',changing_select_change_func);

  function close_click_func(){
    $('.custom-autocomplete-dropdown').remove();
    specificCloseFunctions();
    $(this).parent().fadeOut(400,function(){$(this).remove()});
    deactivateLoadingScreen();
  }

  $('body').on('click', '.close', close_click_func);

  $('body').on('click', '.popup-link', popup_link_func);
}

function activateErrors(){
  // $('.error').delay(3000).fadeOut();
}

function activateCustomAutocomplete(func){
  $('.custom_autocomplete').off('keyup');
  $('.custom_autocomplete').on('keyup',function(e){
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
          choice = func(this);
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

function activateHideBlock(){
  $('.hide-block').off('click');
  $('.hide-block').on('click',function(){
    element = $(this).data('block');
    $(element).toggle(this.checked);
  });
}

function activatePopUp(){
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
             activateClose();
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
             activateClose();
             deactivateLoadingScreen();
          }
      });
    }
    return false;
  });
}

function activateGallery(){
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
    $('.gimage').on('mousemove',function(e){
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
    activateClose();
  });
}

function activateLoadingScreen(){
  $('form').on('submit',function(){

    if(!$(this).hasClass('no-loader') && $(this).children('.no-loader').length == 0) {
      activateLoadingScreen();
    }
  });
  $('input[type=submit]').on('click',function(){

    if(!$(this).hasClass('no-loader')) {
      activateLoadingScreen();
    }
  });
  $('a').on('click',function(){

    if(!$(this).hasClass('no-loader') && !$(this).hasClass('dropdown-toggle') ) {
      activateLoadingScreen();
    }
  });
  $('button').on('click',function(){

    if(!$(this).hasClass('no-loader')) {
      activateLoadingScreen();
    }
  });

  $('.loading-screen').show();
}

function deactivateLoadingScreen(){
  $('.loading-screen').hide();
}

function reloadSelectBoxes(){
  $('select').each(function(select){
    console.log($('select').html());
  });
};

function activateClose(){
  $('.close').off('click');
  $('.close').on('click',function(){
    $('.custom-autocomplete-dropdown').remove();
    specificCloseFunctions();
    $(this).parent().fadeOut().remove();
    deactivateLoadingScreen();
  });
};

function activateReserveAlert(){
  if($('.signal-danger').length > 0){
    $.each($('.signal-danger'),function(){
      alert($(this).data('name')+' è sotto la scorta minima.');
    });
  }
}

function activateFinder(){
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

function activateDelete(){
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

function activateAF(){
  // $('.autofocus').first().focus();
  // // $('.autofocus').val('');
  // $('.autofocus').first().select();
};

function activateDatePicker(date){
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

function preventCr(){
  $('.prevent-cr').on('keypress', function(e){
    if(e.which == 13){
      e.preventDefault();
      e.stopPropagation();
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

  $('.on-top').off('click');
  $('.on-top').on('click',function(e){
    e.stopPropagation();
  });

  $('.hover-hilight').off('click');
  $('.hover-hilight').on('click',function(e){
    var itemRow = $(this);

    if ($(this).data('popup') == true) {
      //$('body').append('<div class="popup">Quantità <input type="number" value="1" step="any" pattern="[0-9]+([\\.,][0-9]+)?" formnovalidate="true" id="amount" name="amount" class="form-control"><div class="close">Chiudi</div></div>');
      $('body').append('<div class="popup">Quantità <input type="text" pattern="[0-9]+([\\.,][0-9]+)?" id="amount" name="amount" data-max="'+$(this).data('max')+'" class="input-number form-control"><div class="close">Chiudi</div></div>');
      $('#amount').val('1');
      $('.popup').css({height: '10em'});
      activateClose();

      $('#amount').focus();
      $('#amount').off('keypress');
      $('#amount').on('keypress',function(e){
        if(e.which == '13'){
          $('.popup').remove();
          // itemRow.find('#chamount').val($(this).val());
          $('#chamount').val($(this).val().replace(',','.'));
          if (parseFloat($('#chamount').val()) > parseFloat($(this).data('max'))){
            $('#chamount').val($(this).data('max'));
          }
          var route = itemRow.data('target');
          itemRow.parents('form').first().append('<input type=hidden name="item" value="'+itemRow.data('data')+'">')

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
      $(this).parents('form').first().append('<input type=hidden name="item" value="'+$(this).data('data')+'">')
      var valuesToSubmit = $(this).parents('form').first().serialize();
      activateLoadingScreen();
      $.ajax({
        method: 'post',
        url: route,
        data: valuesToSubmit
      });
    }
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

  $('.ajax-link').off('click');
  $('.ajax-link').on('click',function(e){
    activateLoadingScreen();
    e.preventDefault();
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

  $('.ajax-link-select').off('change');
  $('.ajax-link-select').on('change',function(e){
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
  $('.ajax-link-stand-alone').on('click',function(e){
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

  $('.popup-link').off('click');
  $('.popup-link').on('click', function(e){
    activateLoadingScreen();
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
           deactivateLoadingScreen();
        }
    });

    return false;

  });

  deactivateLoadingScreen();
};
