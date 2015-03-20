$(function() {
  if ($('.welcome form').length) {
    $('.welcome form select').change(function() {
      $('.welcome form input[type=submit]').removeAttr('disabled');
    });
  };
});