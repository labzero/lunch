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

  $('[data-form-submit-trigger]').on('click', function(e){
    var formName = $(e.currentTarget).data('form-name');
    $('form[name=' + formName + ']').submit();
    e.stopPropagation();
    e.preventDefault();
  });

  $('form:not([data-remote]) input[type=submit]').parents('form').on('submit', function(e) {
    $(this).find('input[type="submit"]').prop('disabled', true);
  });

  $('form input').on('keydown', function(e) {
    if (e.keyCode == 13) {
      e.preventDefault();
      e.stopPropagation();
      var $form = $(e.target).parents('form');
      $form.data('prevent-submit-on-enter') ? null : $form.submit();
    };
  });
});