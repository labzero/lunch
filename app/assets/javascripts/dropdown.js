$(function(){

  var $window = $(window);
  var $dropdown;

  function bindDropdowns() {
    $allDropdowns = $('.dropdown');
    $dropdown = $allDropdowns.filter(':not(.single-item-dropdown)');
    $splitButtonSingleItemDropdowns = $allDropdowns.filter('.single-item-dropdown.split-button-right');

    $dropdown.filter('[data-dropdown-calc-width]').each(function() {
      var $this = $(this);

      // skip if the dropdown has already been initialized.
      if ($this.data('dropdown-initialized')) {
        return;
      };

      var $selection = $this.find('.dropdown-selection');
      var $ul = $this.find('ul');

      // hide the drop down while we open it so that the items have layouts;
      $ul.css('visibility', 'hidden');
      var originalSelection = $selection.text();
      $this.addClass('open');

      // Calculate the max width of each option
      var widths = $this.find('li').map(function() {
        $selection.text($(this).text());
        return $selection.outerWidth();
      }).get();
      var maxWidth = Math.max.apply(Math, widths);

      // Close the dropdown, allow its contents to be shown
      $this.removeClass('open');
      $ul.css('visibility', '');
      $selection.text(originalSelection);

      // Set the width
      $selection.css('width', maxWidth + 1);

      // mark this dropdown as initialized
      $this.data('dropdown-initialized', true);
    });

    $splitButtonSingleItemDropdowns.click(function(event) {
      var $target = $(event.currentTarget);
      $target.siblings('button:only-of-type').click();
    });
  };

  bindDropdowns();

  $('body').on('dropdown-rebind', bindDropdowns);

  $window.on("click", function(event){
    // close all dropdowns if click is happening anywhere that's not a dropdown or a descendant of a dropdown
    if ( $dropdown.has(event.target).length == 0 && !$dropdown.is(event.target) ) {
      $('.dropdown').removeClass('open');
    } else {
      var $target = $(event.target);
      var $parentDropdown = getDropdownEl($target);
      if ( $parentDropdown.length > 0 ) {
        if ($parentDropdown.hasClass('open')) {
          openDropdownClicked($target, $parentDropdown);
        } else {
          closedDropdownClicked($parentDropdown);
        }
      }
    }
  });

  function getDropdownEl($el) {
    if ($el.hasClass('dropdown')) {
      return $el;
    } else {
      return $el.parents('.dropdown') || [];
    };
  };

  function closedDropdownClicked($dropdownEl) {
    $dropdown.removeClass('open');
    $dropdownEl.addClass('open');
  };

  function openDropdownClicked($targetEl, $dropdownEl) {
    var $selectEl = $dropdownEl.find('select');
    $dropdown.removeClass('open'); // close all dropdowns
    // if there is a value for the item you selected and it differs from the current selection, change DOM and trigger change event
    var selectedValue = $targetEl.data('dropdown-value');
    $targetEl.siblings().removeClass('selected');
    $targetEl.addClass('selected');
    if ( selectedValue && selectedValue !== $selectEl.val() ) {
      $selectEl.val(selectedValue);
      $dropdownEl.find('.dropdown-selection').text($targetEl.text());
      $selectEl.trigger('change');
    };
  };

});