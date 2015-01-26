$(function(){

  $('select').on('change', function(event){
    $(event.target).parents('form').submit();
  });

});