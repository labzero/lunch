(function( $ ) {

  $.fn.flyout = function(options) {
    var $flyout = $('.flyout');
    var $flyoutBackground = $('.flyout-background');
    var $flyoutTopSection = $flyout.find('.flyout-top-section');
    var $flyoutBottomSection = $flyout.find('.flyout-bottom-section');
    var $flyoutRow = $('.flyout-row');
    var $flyoutColumn = $flyoutRow.find('.column-1');
    var $closeButton = $flyoutTopSection.find('.flyout-close-button')
    var topContent = options.topContent;
    var bottomContent = options.bottomContent;
    var useReferenceElement = options.useReferenceElement;
    var $that = this;

    if (options.resetContent) {
      resetFlyoutContent();
    }

    if (options.hideCloseButton) {
      $closeButton.hide();
    };

    if (options.rowClass) {
      $flyoutRow.addClass(options.rowClass);
    }
    // initialize flyout by appending elements to the .top-section and .bottom-section.
    $flyoutTopSection.append(topContent);
    if (bottomContent) {
      $flyoutBottomSection.append(bottomContent);
    } else {
      $flyoutBottomSection.hide();
      $flyoutTopSection.addClass('flyout-single-section');
    }

    // give flyout appropriate width and position relative to its reference element
    if (useReferenceElement) {
      $flyoutTopSection.width(this.width());
      $flyout.css({
        'margin-top': this.position()['top'],
        'margin-left': this.position()['left']
      });
    };

    // fade in the background and show the flyout
    $flyoutBackground.fadeIn();
    $flyout.fadeIn();

    this.trigger('flyout-initialized');

    $flyout.on('click', '.flyout-close-button, [data-flyout-action=close]', function(event){
      closeFlyout($that, event);
    });

    $flyout.on('flyout-close', function(event){
      closeFlyout($(event.currentTarget), event);
    });

    function resetFlyoutContent() {
      $closeButton.detach().css('display', '');
      $flyoutTopSection.attr('class', 'flyout-top-section').empty();
      $flyoutTopSection.append($closeButton);
      $flyoutBottomSection.attr('class', 'flyout-bottom-section').empty();
      $flyoutTopSection.width('');
      $flyout.removeClass().addClass('flyout').css({
        'margin-top': '',
        'margin-left': ''
      });
      $flyoutRow.removeClass().addClass('flyout-row');
    };

    function closeFlyout(parentEl, event){
      parentEl.trigger('flyout-reset-initiated');
      $flyoutBackground.fadeOut();
      $flyout.fadeOut(function(){
        resetFlyoutContent();
        $flyout.off();
      });
    };

    return $that;
  };

}( jQuery ));