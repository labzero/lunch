$(function(){

  $('select[name="sta_filter"]').on('change', function(event){
    $(event.target).parents('form').submit();
  });

});