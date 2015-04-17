(function( $ ) {

  $.fn.flyout = function(options) {
    var $flyout = $('.flyout');
    var $flyoutBackground = $('.flyout-background');
    var $flyoutTopSection = $flyout.find('.flyout-top-section');
    var $flyoutBottomSection = $flyout.find('.flyout-bottom-section');
    var topContent = options.topContent;
    var bottomContent = options.bottomContent;
    var useReferenceElement = options.useReferenceElement;
    var closeFlyoutAction = options.closeFlyoutAction;
    var that = this;

    // close flyout if called
    if (closeFlyoutAction) {
      closeFlyout(closeFlyoutAction.parentEl, closeFlyoutAction.event);
      return that;
    };

    // initialize flyout by appending elements to the .top-section and .bottom-section.
    $flyoutTopSection.append(topContent);
    if (bottomContent) {
      $flyoutBottomSection.append(bottomContent);
    } else {
      $flyoutBottomSection.hide();
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

    // height of html must be set to auto
    $('html').css('height', 'auto');

    this.trigger('flyout-initialized');

    $flyout.on('click', '.flyout-close-button, [data-flyout-action=close]', function(event){
      closeFlyout(that, event);
    });

    function closeFlyout(parentEl, event){
      parentEl.trigger('flyout-reset-initiated');
      $flyoutBackground.fadeOut();
      $('html').css('height', '100%'); // set html height back to 100%
      $flyout.fadeOut(function(){
        $flyoutTopSection.attr('class', 'flyout-top-section').children().not(event.target).remove();
        $flyoutBottomSection.attr('class', 'flyout-bottom-section').children().remove();
        $flyoutTopSection.width('');
        $flyout.removeClass().addClass('flyout').css({
          'margin-top': '',
          'margin-left': ''
        });
        $flyout.off();
      });
    };

    return that;
  };

}( jQuery ));