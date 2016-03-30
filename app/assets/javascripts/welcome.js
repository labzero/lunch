$(function() {
  var $form = $('.welcome form');
  if ($form.length) {
    var $memberProfileButton = $form.find('.welcome-profile');
    var $visitProfileField = $form.find('input[name=visit_profile]');
    $('.welcome form select').change(function() {
      $form.find('input[type=submit]').removeAttr('disabled');
      $memberProfileButton.removeAttr('disabled');
    });
    $memberProfileButton.click(function(e) {
      $visitProfileField.removeAttr('disabled');
      $form.attr('target', '_blank');
    });
    $form.submit(function(e) {
      setTimeout(function() {
        $form.removeAttr('target');
        $visitProfileField.attr('disabled', 'disabled');
        $form.get(0).submit();
      }, 1);
    });
  };
});