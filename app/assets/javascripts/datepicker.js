$(function () {

  function bindDatepickers() {
    var startDate, endDate;
    // set up all date-pickers on the page
    $('.datepicker-trigger').each(function(i, datePickerTrigger) {
      var $datePickerTrigger = $(datePickerTrigger);

      if ($datePickerTrigger.data('datepicker-initialized')) {
        return;
      };

      var $wrapper = $($datePickerTrigger.siblings('.datepicker-wrapper'));
      var openDir = $wrapper.data('date-picker-open-direction') || false;
      var singleDatePicker = $wrapper.data('date-picker-single-date-picker') || false;
      var presets = $wrapper.data('date-picker-presets');
      var $form = $($wrapper.data('date-picker-form'));
      var ranges = {};
      var defaultPreset = -1;
      var maxDate = moment($wrapper.data('date-picker-max-date'));
      var minDate = $wrapper.data('date-picker-min-date') ? moment($wrapper.data('date-picker-min-date')) : false;
      var disableWeekends = $wrapper.data('date-picker-disable-weekends') || false;
      var filter = $wrapper.data('date-picker-filter');
      var filterOptions = $wrapper.data('date-picker-filter-options');
      var fromLabel = $wrapper.data('date-picker-from-label');
      var today = $wrapper.data('date-picker-today');
      var linkedInputField = $wrapper.data('date-picker-linked-input-field');
      var invalidDates = $wrapper.data('date-picker-invalid-dates');
      var options = {
        ranges: ranges,
        opens: openDir,
        singleDatePicker: singleDatePicker,
        maxDate: maxDate,
        minDate: minDate,
        filter: filter,
        filterOptions: filterOptions,
        today: today,
        fromLabel: fromLabel,
        disableWeekends: disableWeekends
      };
      startDate = $wrapper.data('date-picker-start-date');
      endDate = $wrapper.data('date-picker-end-date');
      $.each(presets, function(index, preset) {
        if (preset.start_date) {
          preset.start_date = moment(preset.start_date);
        };
        if (preset.end_date) {
          preset.end_date = moment(preset.end_date);
        };
        ranges[preset.label] = [preset.start_date, preset.end_date]
        if (preset.is_default) {
          defaultPreset = index;
        };
      });

      if (startDate) {
        startDate = moment(startDate);
      }

      if (endDate) {
        endDate = moment(endDate);
      }

      if (defaultPreset >= 0) {
        startDate = presets[defaultPreset].start_date;
        endDate = presets[defaultPreset].end_date;
        options.defaultPreset = defaultPreset;
      }

      options.startDate = startDate;
      options.endDate = endDate;

      initializeDatePicker($datePickerTrigger, $wrapper, options);
      setDatePickerApplyListener($datePickerTrigger, $form, linkedInputField);
      $.isArray(invalidDates) ? disableInvalidDatesForCalendar($datePickerTrigger, $wrapper, invalidDates) : false; // Disable invalid dates if present
      options.disableWeekends ? disableWeekendsForCalendar($datePickerTrigger, $wrapper) : false;
      setDatePickerPlaceholder($datePickerTrigger, startDate, endDate);
      if (filter !== undefined) {
        if (singleDatePicker) {
          $datePickerTrigger.on('updateCalendar.daterangepicker showCalendar.daterangepicker show.daterangepicker', function(){
            filterDates(filter, filterOptions);
          });
        };
      };
      $datePickerTrigger.data('datepicker-initialized', true);
    });
    var $datePickerFields = $(".datepicker_input_field .input-mini");
    var $datePickerWrapper = $('.datepicker-wrapper');
    $datePickerFields.keypress(function(e) {
      Fhlb.Utils.onlyAllowDigits(e, [47]); // 47 = / (forward slash)
    });

    $datePickerFields.keyup(function(e) {
      normalizeDateFormatPreservingSelection(e);
      changeApplyButtonStatus($datePickerWrapper, false);
    });

    $datePickerFields.change(function(e) {
      var target = e.target;
      if (target.value.match(/[0-9]+\/[0-9]+\/[0-9]+/)) {
        normalizeDateFormatPreservingSelection(e);
      } else {
        $(target).val((target.name == 'daterangepicker_start' ? startDate : endDate).format('MM/DD/YYYY'));
      };
    });
  };

  bindDatepickers();

  $('body').on('datepicker-rebind', bindDatepickers);

  function normalizeDateFormatPreservingSelection(e) {
    if ([8, 9, 13, 16, 17, 18, 19, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 45, 46].indexOf(e.which) < 0) {
      var target = e.target;
      var selectionStart = target.selectionStart;
      var selectionEnd = target.selectionEnd;
      var oldValue = target.value;
      var newValue = oldValue.match(/[\d\/]+/);

      if (newValue !== oldValue) {
        try {
          target.innerText = newValue;
        } catch(_e) {
          $(target).val(newValue);
        };
        target.setSelectionRange(selectionStart, selectionEnd);
      };
    };
  };

  function initializeDatePicker($datePickerTrigger, $datePickerWrapper, options) {
    var optionsHash = {
      startDate: options.startDate,
      endDate: options.endDate,
      ranges: options.ranges,
      maxDate: options.maxDate,
      minDate: options.minDate,
      today: options.today,
      parentEl: $datePickerWrapper,
      locale: {
        cancelLabel: '',
        fromLabel: options.fromLabel
      },
      opens: options.opens,
      singleDatePicker: options.singleDatePicker,
      linkedInputField: options.linkedInputField
    };
    $datePickerTrigger.daterangepicker(optionsHash);
    addUpdateEventTrigger($datePickerTrigger);
    $datePickerTrigger.daterangepicker(optionsHash); // reinitialize the datepicker with the prototype changes made by `addUpdateEventTrigger`

    // Disable apply button
    var disableApply = true;

    if ($.isEmptyObject(options.ranges)) {
      $datePickerWrapper.addClass('datepicker-wrapper-no-presets');
      disableApply = false;
    };

    changeApplyButtonStatus($datePickerWrapper, disableApply);
    blockDefaultButtonActions($datePickerWrapper);

    // Append the daterangepicker's start and end inputs to our own div for design purposes, then attach its event handlers
    var $datePickerStartInput = $datePickerWrapper.find('.daterangepicker_start_input');
    var $datePickerEndInput = $datePickerWrapper.find('.daterangepicker_end_input');
    $datePickerWrapper.find('.daterangepicker').prepend('<div class="datepicker_input_field"><div class="daterangepicker_start_input_wrapper"></div><div class="daterangepicker_end_input_wrapper"></div></div>');
    $datePickerEndInput.prependTo($('.daterangepicker_end_input_wrapper'));
    $datePickerStartInput.prependTo($('.daterangepicker_start_input_wrapper'));

    $([$datePickerEndInput, $datePickerStartInput]).each(function(){this.on('change', function(e) {
      convertTwoDigitYearToFourDigitYear(e, $datePickerTrigger.data('daterangepicker'), options);
      snapToValidDate(e, $datePickerTrigger.data('daterangepicker'), options);
      $datePickerTrigger.data('daterangepicker').inputsChanged(e)});})
    $datePickerWrapper.find('.calendar, .ranges').off('mouseenter mouseleave'); // daterangepicker binds these unwanted events

    $datePickerWrapper.find('.daterangepicker .ranges').insertBefore($datePickerWrapper.find('.calendar.first'));
    $datePickerWrapper.find('.range_inputs').html($datePickerWrapper.find('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons
    $datePickerWrapper.find('.ranges li:last-child').hide(); // hide the custom range preset
    if (options.defaultPreset) {
      $($datePickerWrapper.find('.ranges li')[options.defaultPreset]).click(); // default to "Last Month" when first opening
    }
    if (options.singleDatePicker) {
      $datePickerWrapper.find('.ranges').show(); // always show the pre-selected tabs (daterangepicker.js hides these when set with the option singleDatePicker
    }

  };

  // change apply button status
  function changeApplyButtonStatus($datePickerWrapper, disabled)  {
    var $applyButton = $datePickerWrapper.find('button.applyBtn.btn.btn-small.btn-sm.btn-success');
    $applyButton.attr('disabled', disabled);
  };

  // accessing the start and end dates once the apply button is pressed
  function setDatePickerApplyListener($datePickerTrigger, $form, linkedInputField){
    $datePickerTrigger.on('apply.daterangepicker', function(ev, picker) {
      ev.stopPropagation();
      setDatePickerPlaceholder($datePickerTrigger, picker.startDate, picker.endDate);
      $form.find('input[name=start_date]').val(picker.startDate.format('YYYY-MM-DD'));
      if (linkedInputField) {
        $('input[name="' + linkedInputField + '"]').val(picker.startDate.format('YYYY-MM-DD'));
      }
      if (!$($datePickerTrigger.siblings('.datepicker-wrapper')).data('date-picker-single-date-picker')) {
        $form.find('input[name=end_date]').val(picker.endDate.format('YYYY-MM-DD'));
      }
      $form.submit();
    });
  };

  function setDatePickerPlaceholder($datePickerTrigger, startDate, endDate) {
    if ($($datePickerTrigger.siblings('.datepicker-wrapper')).data('date-picker-single-date-picker')) {
      var input_field_text = $datePickerTrigger.data('date-picker-input-field-text').replace(/\{replace_date\}/, startDate.format('MM/DD/YYYY'));
      $datePickerTrigger.find('input').val(input_field_text);
    }
    else {
      $datePickerTrigger.find('input').val(startDate.format('MM/DD/YYYY') + ' - ' + endDate.format('MM/DD/YYYY'));
    };
  };

  function blockDefaultButtonActions($datePickerWrapper) {
    $datePickerWrapper.click(function(e) {
      e.preventDefault();
    });
  };

  function filterDates(filter, filterOptions) {
    var monthMoment = moment($('.calendar.first .month').text(), 'MMM YYYY');
    var lastDayOfMonth = monthMoment.endOf('month').date();
    switch (filter) {
      case filterOptions['end_of_month']:
        disableAllExceptEndOfMonth(lastDayOfMonth);
        break;
      case filterOptions['end_of_quarter']:
        // disable all dates except 3/31, 6/30, 9/30, 12/31
        var month = monthMoment.month();
        if (month === 2 || month === 5 || month === 8 || month === 11) {
          disableAllExceptEndOfMonth(lastDayOfMonth);
        } else {
          $('.calendar.first td.available').each(disableDayIterator);
        };
        break;
    };
  };

  function disableAllExceptEndOfMonth(day) {
    var possibleMonthEndNodes = [];
    $('.calendar.first td.available').each(function(i){
      var $node = $(this);
      if ($node.text() != day) {
        disableDay($node);
      } else {
        possibleMonthEndNodes.push($node);
      };
    });
    possibleMonthEndNodes.pop(); // the last node is the one we want to leave enabled, the others are from other months
    $(possibleMonthEndNodes).each(disableDayIterator);
  };

  function disableDay($node) {
    $node.removeClass('available in-range');
    $node.addClass('off disabled');
  };

  function disableDayIterator(index, $node) {
    disableDay($node);
  };

  function disableInvalidDatesForCalendar($datePickerTrigger, wrapper, invalidDates) {
    var $wrapper = $(wrapper);
    $datePickerTrigger.on('updateCalendar.daterangepicker showCalendar.daterangepicker show.daterangepicker', function(e, picker) {
      var monthYearMoment = moment($wrapper.find('.calendar.first .month').text(), 'MMM YYYY');
      var thisMonthsDateCells = $wrapper.find('td.available:not(".off")');
      var lastMonthsDateCells = [];
      var nextMonthsDateCells = [];
      var availableOffCells = $wrapper.find('td.available.off');
      $.each(availableOffCells, function(i, dateCell) {
        var integerDate = parseInt($(dateCell).text());
        var rowNumber = parseRowFromDateCell(dateCell);
        if (integerDate > 20 && rowNumber === '0') {
          lastMonthsDateCells.push(dateCell);
        }
        else if (integerDate < 15 && (rowNumber === '4' || rowNumber === '5')) {
          nextMonthsDateCells.push(dateCell);
        };
      });

      disableNodesByInvalidDates(thisMonthsDateCells, invalidDates, monthYearMoment);
      disableNodesByInvalidDates(lastMonthsDateCells, invalidDates, monthYearMoment.clone().subtract(1, 'month'));
      disableNodesByInvalidDates(nextMonthsDateCells, invalidDates, monthYearMoment.clone().add(1, 'month'));
    });
  };

  function disableWeekendsForCalendar($datePickerTrigger, wrapper) {
    var $wrapper = $(wrapper);
    $datePickerTrigger.on('updateCalendar.daterangepicker showCalendar.daterangepicker show.daterangepicker', function(e, picker) {
      $wrapper.find('tbody td:first-child, tbody td:last-child').each(function(i, dateCell) {
        disableDay($(dateCell));
      });
    });
  };

  function parseRowFromDateCell(dateCell) {
    var regex = /r([\d])/i;
    var regexResults = regex.exec($(dateCell).data('title'));
    if ($.isArray(regexResults)) {
      return regexResults[1];
    };
  };

  function disableNodesByInvalidDates(dateNodes, invalidDates, monthYearMoment) {
    $.each(dateNodes, function(i, dateCell) {
      var $dateCell = $(dateCell);
      if (invalidDates.indexOf(monthYearMoment.clone().set('date', $dateCell.text()).format('YYYY-MM-DD')) > -1) {
        disableDay($dateCell);
      };
    });
  };

  // monkeypatch DateRangePicker to trigger event when calendar is updated
  function addUpdateEventTrigger(picker) {
    var picker = $(picker).data('daterangepicker');
    var pickerPrototype = Object.getPrototypeOf(picker);
    var updateCalendarsOld = pickerPrototype.updateCalendars;
    if (!updateCalendarsOld.fhlbModified) {
      pickerPrototype.updateCalendars = function () {
        var oldResults = updateCalendarsOld.apply(this);
        this.element.trigger('showCalendar.daterangepicker', this);
        return oldResults;
      };
      pickerPrototype.updateCalendars.fhlbModified = true;
    };
  };

  function snapToValidDate(e, picker, options){
    //  snap to maxDate or minDate if date is out of range
    var maxDate = moment(options.maxDate);
    var minDate = moment(options.minDate);
    var today = moment(options.today);
    var thisMonth = moment().month();
    var thisYear = moment().year();
    var $el = $(e.target);
    var date = moment($el.val());
    if (date > maxDate || date < minDate) {
      date = date > maxDate ? maxDate : minDate;
      options.singleDatePicker ? picker.setEndDate(date.format('MM/DD/YYYY')) : null;
      $el.val(date.format('MM/DD/YYYY'));
    } else if (options.singleDatePicker) {
      picker.setEndDate(date.format('MM/DD/YYYY'));
      $el.val(date.format('MM/DD/YYYY'));
    };

    // apply filters if necessary
    if (options.singleDatePicker && options.filter !== undefined && options.filterOptions !== undefined) {
      var inputMonth = date.month();
      var inputYear = date.year();
      var endOfMonth = moment(date).endOf('month').startOf('day'); // clone so that `endOf` does not mutate original `date`
      switch (options.filter) {
        // Snap to end of month
        case options.filterOptions['end_of_month']:
          if (date != endOfMonth) {
            if (endOfMonth > maxDate) {
              date.subtract(1, 'month');
            }
            date.endOf('month');
          }
          picker.setEndDate(date);
          $el.val(date.format('MM/DD/YYYY')); // uses the mutated value of `date` set in the if/else statement above
          break;
        // Snap to end of quarter
        case options.filterOptions['end_of_quarter']:
          var endOfQuarter;
          var endOfLastQuarter;
          var setQuarter

          if (inputMonth <= 2) {
            endOfQuarter = moment(date.year()+'/3/31');
            endOfLastQuarter = moment((date.year() - 1)+'/12/31');
          } else if (inputMonth <= 5) {
            endOfQuarter = moment(date.year()+'/6/30');
            endOfLastQuarter = moment(date.year()+'/3/31');
          } else if (inputMonth <= 8) {
            endOfQuarter = moment(date.year()+'/9/30');
            endOfLastQuarter = moment(date.year()+'/6/30');
          } else if (inputMonth <= 12) {
            endOfQuarter = moment(date.year()+'/12/31');
            endOfLastQuarter = moment(date.year()+'/9/30');
          };

          setQuarter = endOfQuarter > today ? endOfLastQuarter : endOfQuarter;
          picker.setEndDate(setQuarter);
          $el.val(setQuarter.format('MM/DD/YYYY'));
          break;
      };
    };
  };

  // converts two-digit dates to four-digit dates following the java conventions set forth here:
  // http://docs.oracle.com/javase/6/docs/api/java/text/SimpleDateFormat.html#year
  function convertTwoDigitYearToFourDigitYear(e, picker, options) {
    if (e.target.value.search(/(.*)\/(.*)\/(.*)/) !== -1) {
      var dateArray = e.target.value.split("/");
      var monthString = dateArray[0];
      var dayString = dateArray[1];
      var yearString = dateArray[2];
      var $el = $(e.target);
      if (yearString === "" || isNaN(yearString)) {
        return;
      }
      if (yearString.length == 2) {
        var yearInt = parseInt(yearString);

        var lowerBound = new Date();
        lowerBound.setFullYear(lowerBound.getFullYear() - 80);

        if ((1900 + yearInt) > lowerBound.getFullYear()) {
          var date = moment(monthString + "/" + dayString + "/" + (1900 + yearInt));
          if (options.singleDatePicker) {
            picker.setEndDate(date);
            $el.val(date.format('MM/DD/YYYY'));
          } else {
            if ($(e.currentTarget).hasClass("daterangepicker_start_input")) {
              picker.setStartDate(date);
              $el.val(date.format('MM/DD/YYYY'));
            }
            if ($(e.currentTarget).hasClass("daterangepicker_end_input")) {
              picker.setEndDate(date);
              $el.val(date.format('MM/DD/YYYY'));
            }
          }
          return;
        }

        var upperBound = new Date();
        upperBound.setFullYear(upperBound.getFullYear() + 20);

        if ((2000 + yearInt) < upperBound) {
          var date = moment(monthString + "/" + dayString + "/" + (2000 + yearInt));
          if (options.singleDatePicker) {
            picker.setEndDate(date);
            $el.val(date.format('MM/DD/YYYY'));
          } else {
            if ($(e.currentTarget).hasClass("daterangepicker_start_input")) {
              picker.setStartDate(date);
              $el.val(date.format('MM/DD/YYYY'));
            }
            if ($(e.currentTarget).hasClass("daterangepicker_end_input")) {
              picker.setEndDate(date);
              $el.val(date.format('MM/DD/YYYY'));
            }
          }
        }
      }
    }
  };



});