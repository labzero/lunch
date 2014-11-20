(function( $ ) {

  $.fn.flyout = function(topContent, bottomContent) {
    var $flyout = $('.flyout');
    var $flyoutBackground = $('.flyout-background');
    var $flyoutTopSection = $flyout.find('.flyout-top-section');
    var $flyoutBottomSection = $flyout.find('.flyout-bottom-section');
    var $flyoutCloseButton = $flyout.find('.flyout-close-button');

    // initialize flyout by appending elements to the .top-section and .bottom-section.
    $flyoutTopSection.append(topContent);
    $flyoutBottomSection.append(bottomContent);

    // give flyout appropriate width and position relative to its reference element
    $flyoutTopSection.width(this.width());
    $flyout.css({
      'top': this.position()['top'],
      'left': this.position()['left']
    });

    // fade in the background and show the flyout
    $flyoutBackground.fadeIn();
    $flyout.fadeIn();

    this.trigger('flyout-initialized');

    var that = this;
    // teardown the background and reset the flyout
    $flyoutCloseButton.on('click', function(event){
      that.trigger('flyout-reset-initiated');
      $flyoutBackground.fadeOut();
      $flyout.fadeOut(function(){
        $flyoutTopSection.attr('class', 'flyout-top-section').children().not(event.target).remove();
        $flyoutBottomSection.attr('class', 'flyout-bottom-section').children().remove();
        $flyoutTopSection.width('');
        $flyout.removeClass().addClass('flyout').css({
          'top': '',
          'left': ''
        });
        $flyoutCloseButton.off();
      });
    });

    return this;
  };

}( jQuery ));