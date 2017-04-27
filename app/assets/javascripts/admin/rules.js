$(function() {
  var $rules_limits_text_fields = $('.rules-limits-form input[type=text]').on('keydown');
  $rules_limits_text_fields.on('keypress', function(e){
    Fhlb.Utils.onlyAllowDigits(e);
  });
  $rules_limits_text_fields.on('keyup', function(e){
    Fhlb.Utils.addCommasToInputField(e);
  });
});