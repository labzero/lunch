window.ClientSideValidations.formBuilders['ActionView::Helpers::FormBuilder'] = {
  add: function(element, settings, message) {
    var id = element.attr('id');
    element.addClass('input-field-error');
    var $container = element.parents('.input-field-container');
    $container.addClass('input-field-container-error');
    $container.siblings('label[for=' + id + ']').addClass('label-error');
    // We need to have the label already in the DOM, otherwise the focus event blocks click events in chrome
    var $label = $container.find('label.label-error');
    $label.attr('for', id);
    return $label.text(message);
  },

  remove: function(element, settings) {
    var id = element.attr('id');
    var $container = element.parents('.input-field-container');
    element.removeClass('input-field-error');
    $container.siblings('label[for=' + id + ']').removeClass('label-error');
    setTimeout(function() { // Work around for a DOM bug in chrome where the event blur never results in a click if we manipulate the DOM geometry
      if (!element.hasClass('input-field-error')) {
        var $container = element.parents('.input-field-container');
        $container.removeClass('input-field-container-error');
      };
    }, 1);
  }
}