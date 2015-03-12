$(function(){
  $('.advances-detail-report .detail-view-trigger').on('click', function(event){
    $('.advances-detail-report tr').removeClass('detail-view');
    event.stopPropagation();
    $(event.target).closest('tr').addClass('detail-view');
    advanceDetailEventListener();
  });

  function advanceDetailEventListener() {
    var $window = $(window);
    var $advanceDetails = $('.advances-detail-report .advance-details');
    $window.on("click.advanceDetailOpen", function(event){
      if ( ($advanceDetails.has(event.target).length == 0 && !$advanceDetails.is(event.target)) || $(event.target).hasClass('hide-detail-view') ) {
        $('.advances-detail-report tr').removeClass('detail-view');
        $window.off('click.advanceDetailOpen');
      };
    });
  };

});