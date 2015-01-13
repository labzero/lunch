$(function () {

  // set up all date-pickers on the page
  $('.datepicker-trigger').each(function(i, datePickerTrigger) {

    var $datePickerTrigger = $(datePickerTrigger);
    var $wrapper = $($datePickerTrigger.siblings('.datepicker-wrapper'));
    var openDir = $wrapper.data('date-picker-open-direction') || false;
    var presets = $wrapper.data('date-picker-presets');
    var $form = $($wrapper.data('date-picker-form'));
    var ranges = {};
    var lastCustomLabel;
    var defaultPreset = 1;
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
      if (preset.is_default) {
        defaultPreset = index;
      };
    });

    var startDate = presets[defaultPreset].start_date;
    var endDate = presets[defaultPreset].end_date

    initializeDatePicker($datePickerTrigger, $wrapper, {
      ranges: ranges,
      customLabel: lastCustomLabel,
      opens: openDir,
      defaultPreset: defaultPreset,
      startDate: startDate,
      endDate: endDate
    });
    datePickerSelectionHandler($datePickerTrigger, $wrapper, presets);
    setDatePickerApplyListener($datePickerTrigger, $form);
    setDatePickerPlaceholder($datePickerTrigger, startDate, endDate);
  });

  function initializeDatePicker($datePickerTrigger, $datePickerWrapper, options) {
    $datePickerTrigger.daterangepicker(
      {
        startDate: options.startDate,
        endDate: options.endDate,
        ranges: options.ranges,
        parentEl: $datePickerWrapper,
        locale: {
          customRangeLabel: options.customLabel,
          cancelLabel: ''
        },
        opens: options.opens
      }
    );
    $datePickerWrapper.find('.daterangepicker .ranges').insertBefore($datePickerWrapper.find('.calendar.first'));
    $datePickerWrapper.find('.range_inputs').html($datePickerWrapper.find('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons
    $($datePickerWrapper.find('.ranges li')[options.defaultPreset]).click(); // default to "Last Month" when first opening
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
            
            if (preset.start_date) {
              $datePickerTrigger.data('daterangepicker').setStartDate(preset.start_date);
            };

            if (preset.end_date) {
              $datePickerTrigger.data('daterangepicker').setEndDate(preset.end_date);
            };
          } else {
            $datePickerWrapper.find('.calendar').show();
          };
        };
      });
    });
  };

  // accessing the start and end dates once the apply button is pressed
  function setDatePickerApplyListener($datePickerTrigger, $form){
    $datePickerTrigger.on('apply.daterangepicker', function(ev, picker) {
      ev.stopPropagation();
      setDatePickerPlaceholder($datePickerTrigger, picker.startDate, picker.endDate);
      $form.find('input[name=start_date]').val(picker.startDate.format('YYYY-MM-DD'));
      $form.find('input[name=end_date]').val(picker.endDate.format('YYYY-MM-DD'));
      $form.submit();
    });
  };

  function setDatePickerPlaceholder($datePickerTrigger, startDate, endDate) {
    $datePickerTrigger.find('input').attr('placeholder', startDate.format('MMMM D, YYYY') + ' - ' + endDate.format('MMMM D, YYYY'));
  }

});