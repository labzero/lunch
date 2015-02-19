$(function(){

  $('select').on('change', function(event){
    // TODO remove this conditional once you rig up selecting different historical price indications reports
    var $target = $(event.target);
    if ($target.attr('name') !== 'historical_price_collateral_type' && $target.attr('name') !== 'historical_price_credit_type') {
      $target.parents('form').submit();
    }
  });

});