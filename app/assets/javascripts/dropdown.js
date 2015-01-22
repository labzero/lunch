$(function(){

  var $window = $(window);
  var $dropdown = $('.dropdown');
  $window.on("click", function(event){
    // close all dropdowns if click is happening anywhere that's not a dropdown or a descendant of a dropdown
    if ( $dropdown.has(event.target).length == 0 && !$dropdown.is(event.target) ) {
      $('.dropdown').removeClass('open');
    } else {
      var $target = $(event.target);
      var $parentDropdown;
      if ($target.hasClass('dropdown')) {
        $parentDropdown = $target;
      } else {
        $parentDropdown = $target.parents('.dropdown') || [];
      };
      var selectedValue = $target.data('dropdown-value');
      if ($parentDropdown.length > 0 || $target.hasClass('dropdown')) {
        if ($parentDropdown.hasClass('open')) {
          $dropdown.removeClass('open');
          // if there is a value for the item you selected and it differs from the current selection, trigger event and DOM changes
          if ( selectedValue && selectedValue !== $parentDropdown.data('dropdown-value') ) {
            $parentDropdown.data('dropdown-value', selectedValue);
            $($parentDropdown.find('input')).val($target.text());
            var eventName = $($parentDropdown).data('dropdown-name') + '-dropdown-event';
            var dropdownEvent = {type: eventName, value: selectedValue};
            $parentDropdown.trigger(dropdownEvent);
          }
        } else {
          $dropdown.removeClass('open');
          $parentDropdown.addClass('open');
        }
      }
    }
  });

});