$(function(){
  $('.sidebar-filter span:not(".active")').on('click', function(event){
    var $target = $(event.target);
    var $selectEl = $('.sidebar-filter select');
    var value = $target.data('sidebar-value');
    $selectEl.val(value);
    $selectEl.trigger('change');
  });
});