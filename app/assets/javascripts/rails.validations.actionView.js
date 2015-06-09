window.ClientSideValidations.formBuilders['ActionView::Helpers::FormBuilder'] = {
  add: function(element, settings, message) {
    element.addClass('input-field-error');
    var $container = element.parents('.input-field-container');
    $container.addClass('input-field-container-error');
    // We need to have the label already in the DOM, otherwise the focus event blocks click events in chrome
    var $label = $container.find('label.label-error');
    $label.attr('for', element.attr('id'));
    return $label.text(message);
  },

  remove: function(element, settings) {
    element.removeClass('input-field-error');
    setTimeout(1, function() { // Work around for a DOM bug in chrome where the event blur never results in a click if we manipulate the DOM geometry
      if (!element.hasClass('input-field-error')) {
        var $container = element.parents('.input-field-container');
        $container.removeClass('input-field-container-error');
      };
    });
  }
}