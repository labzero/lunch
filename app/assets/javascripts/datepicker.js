$(function () {

  // set up all date-pickers on the page
  $('.datepicker-trigger').each(function(i, datePickerTrigger) {

    var $datepickerTrigger = $(datePickerTrigger);
    var $wrapper = $($datepickerTrigger.siblings('.datepicker-wrapper'));
    var presets = $wrapper.data('date-picker-presets');
    var ranges = {};
    var lastCustomLabel;
    $.each(presets, function(index, preset) {
      if (preset.start_date) {
        preset.start_date = moment(preset.start_date);
      };
      if (preset.end_date) {
        preset.end_date = moment(preset.end_date);
      };
      if (!preset.is_custom) {
        ranges[preset.label] = [preset.start_date, preset.end_date]
      } else {
        lastCustomLabel = preset.label;
      };
    });

    initializeDatePicker($datepickerTrigger, $wrapper, {ranges: ranges, customLabel: lastCustomLabel});
    datePickerSelectionHandler($datepickerTrigger, $wrapper, presets);
    setDatePickerApplyListener($datepickerTrigger);
  });

  function initializeDatePicker($datePickerTrigger, $datePickerWrapper, options) {
    $datePickerTrigger.daterangepicker(
      {
        ranges: options.ranges,
        parentEl: $datePickerWrapper,
        locale: {
          customRangeLabel: options.customLabel,
          cancelLabel: ''
        }
      }
    );
    $datePickerWrapper.find('.daterangepicker .ranges').insertBefore($datePickerWrapper.find('.calendar.first'));
    $datePickerWrapper.find('.range_inputs').html($datePickerWrapper.find('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons
    $($datePickerWrapper.find('.ranges li')[1]).click(); // default to "Last Month" when first opening
  };

  // Choosing "This Month" or "Last Month" shouldn't close the datepicker until the apply button is pressed
  function datePickerSelectionHandler($datePickerTrigger, $datePickerWrapper, presets){
    $datePickerWrapper.find('.ranges ul li').each(function(index, label) {
      var $label = $(label);
      $(label).on('click', function(event){
        event.stopPropagation();
        $('.ranges ul li').removeClass('active');
        $label.addClass('active');
        if (presets[index]) {
          var preset = presets[index];
          if (!preset.is_custom) {
            $datePickerWrapper.find('.calendar').hide();
          } else {
            $datePickerWrapper.find('.calendar').show();
          };

          if (preset.start_date) {
            $datePickerTrigger.data('daterangepicker').setStartDate(preset.start_date);
          };

          if (preset.end_date) {
            $datePickerTrigger.data('daterangepicker').setEndDate(preset.end_date);
          };
        };
      });
    });
  };

  // accessing the start and end dates once the apply button is pressed
  function setDatePickerApplyListener($datePickerTrigger){
    $datePickerTrigger.on('apply.daterangepicker', function(ev, picker) {
      ev.stopPropagation();
      $datePickerTrigger.find('input').attr('placeholder', picker.startDate.format('MMMM D, YYYY') + ' - ' + picker.endDate.format('MMMM D, YYYY'));
    });
  };

});