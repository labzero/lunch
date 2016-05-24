$(function() {
  $('form input[type=checkbox][name=check_all]').on('change', function(){
    var $this = $(this);
    var $form = $this.parents('form');
    var $checkboxes = $form.find('input[type=checkbox]');
    $checkboxes.prop('checked', $this.prop("checked"));
    $checkboxes.on('change', function(e){
      var $checkedBoxes = $form.find('input[type=checkbox]:checked');
      var checkedBoxLength = $this[0].checked ? $checkedBoxes.length : $checkedBoxes.length + 1;
      $this.prop('checked', checkedBoxLength > 0 && checkedBoxLength === ($checkboxes.length))
    });
  });

  $('form').on('submit', function(e){
    $(this).find('input[type=checkbox][name=check_all]').attr('checked', false);
  });

});