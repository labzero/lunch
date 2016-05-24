$(function() {
  var $form = $('.manage-securities-form');
  var $checkboxes = $form.find('input[type=checkbox]');
  var $submitButton = $form.find('input[type=submit]');
  $checkboxes.on('change', function(e){
    // if boxes checked and all values are the same, enable submit
    var status = false;
    $form.find('input[type=checkbox]:checked').each(function(){
      var thisStatus = $(this).data('status');
      if (!status) {
        status = thisStatus;
      }
      else if (thisStatus != status) {
        status = false;
        return false;
      };
    });
    if (status) {
      $submitButton.attr('disabled', false);
    } else {
      $submitButton.attr('disabled', true);
    };
  });
});