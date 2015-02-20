$(function(){

  $('select').on('change', function(event){
    // TODO remove this conditional once you rig up selecting different historical price indications reports
    var $target = $(event.target);
    if ($target.attr('name') !== 'historical_price_collateral_type' && ($target.attr('name') !== 'historical_price_credit_type' || $.inArray($target.val(), ['frc', 'vrc', '1m_libor', '3m_libor', '6m_libor', 'daily_prime']) > -1)) {
      $target.parents('form').submit();
    }
  });

  // TODO remove this quick fix that disables the `sbc` collateral_type option on the Historic Price Indications page once it is rigged up
  $('select[name=historical_price_collateral_type] option[value=sbc]').attr('disabled', true)

});