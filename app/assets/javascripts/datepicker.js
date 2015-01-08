$(function () {
  var $wrapper = $('.datepicker-wrapper');
  var lastMonthLabel = $wrapper.data('options-labels-last-month');
  var thisMonthLabel = $wrapper.data('options-labels-this-month');
  var customLabel = $wrapper.data('options-labels-custom');
  var startOfThisMonth = moment().startOf('month');
  var today = moment();
  var startOfLastMonth = moment().subtract('month', 1).startOf('month');
  var endOfLastMonth = moment().subtract('month', 1).endOf('month')

  var ranges = {};
  ranges[thisMonthLabel] = [moment().startOf('month'), moment()];
  ranges[lastMonthLabel] = [moment().subtract('month', 1).startOf('month'), moment().subtract('month', 1).endOf('month')]
  $('#reportrange').daterangepicker(
    {
      ranges: ranges,
      parentEl: '.datepicker-wrapper',
      locale: {
        customRangeLabel: customLabel
      }
    }
  );

  // add code to restructure the html of the datepicker - hacky, but the html is hardcoded in Grossman's code
  $('.daterangepicker .ranges').insertBefore('.calendar.first');
  $('.range_inputs').html($('.range_inputs').html().replace(/&nbsp;/g, '')); // get rid of whitespace added between hidden buttons

  // default to "Last Month" when first opening
  $($wrapper.find('.ranges li')[1]).click();

  // Choosing "This Month" or "Last Month" shouldn't close the datepicker until the apply button is pressed
  $('.ranges ul li').each(function(i, label) {
    var $label = $(label);
    var index = i;
    $(label).on('click', function(event){
      event.stopPropagation();
      $('.ranges ul li').removeClass('active');
      $label.addClass('active');
      if (index === 0) {
        // this month
        $('.daterangepicker .calendar').hide();
        $('#reportrange').data('daterangepicker').setStartDate(startOfThisMonth);
        $('#reportrange').data('daterangepicker').setEndDate(today);
      } else if (index === 1) {
        // last month
        $('.daterangepicker .calendar').hide();
        $('#reportrange').data('daterangepicker').setStartDate(startOfLastMonth);
        $('#reportrange').data('daterangepicker').setEndDate(endOfLastMonth);
      } else if (index === 2) {
        // custom
        $('.daterangepicker .calendar').show(); // you've hit the custom range flow
      }
    });
  });

  // accessing the start and end dates once the apply button is pressed
  $('#reportrange').on('apply.daterangepicker', function(ev, picker) {
    $('#reportrange input').attr('placeholder', picker.startDate.format('MMMM D, YYYY') + ' - ' + picker.endDate.format('MMMM D, YYYY'));
  });

  // What happens when there is more than one datepicker on a given page? Need to initialize each one and have it refer to itself
});