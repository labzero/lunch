(function( $ ) {

  $.fn.flyout = function(topContent, bottomContent) {
    var $flyout = $('.flyout');
    var $flyoutBackground = $('.flyout-background');
    var $flyoutTopSection = $flyout.find('.flyout-top-section');
    var $flyoutBottomSection = $flyout.find('.flyout-bottom-section');

    // initialize flyout by appending elements to the .top-section and .bottom-section.
    $flyoutTopSection.append(topContent);
    $flyoutBottomSection.append(bottomContent);

    // give flyout appropriate width and position relative to its reference element
    $flyoutTopSection.width(this.width());
    $flyout.css({
      'margin-top': this.position()['top'],
      'margin-left': this.position()['left']
    });

    // fade in the background and show the flyout
    $flyoutBackground.fadeIn();
    $flyout.fadeIn();

    // height of html must be set to auto
    $('html').css('height', 'auto');

    this.trigger('flyout-initialized');

    var that = this;
    // teardown the background and reset the flyout
    $flyout.on('click', '.flyout-close-button, [data-flyout-action=close]', function(event){
      that.trigger('flyout-reset-initiated');
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
    });

    return this;
  };

}( jQuery ));