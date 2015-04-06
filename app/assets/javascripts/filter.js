$(function(){

  $('.report .report-inputs select').on('change', function(event){
    // TODO remove this conditional once you rig up selecting different historical price indications reports
    var $target = $(event.target);
    if ($target.attr('name') !== 'historical_price_credit_type' || $.inArray($target.val(), ['frc', 'vrc', '1m_libor', '3m_libor', '6m_libor', 'daily_prime']) > -1) {
      $target.parents('form').submit();
    }
  });

});