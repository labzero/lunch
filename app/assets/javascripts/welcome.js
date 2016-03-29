$(function() {
  if ($('.welcome form').length) {
    var $memberProfileButton = $('.welcome form .welcome-profile');
    $('.welcome form select').change(function() {
      $('.welcome form input[type=submit]').removeAttr('disabled');
      $memberProfileButton.removeAttr('disabled');
    });
    $memberProfileButton.click(function(e) {
      $('.welcome form input[name=visit_profile').removeAttr('disabled');
      $('.welcome form').attr('target', '_blank');
    });
    $('.welcome form').submit(function(e) {
      setTimeout(function() {$('.welcome form').removeAttr('target');}, 1);
    });
  };
});