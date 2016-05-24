$(function() {

  function bindTables() {
    $('.report-table').each(function() {
      var $dataTable;
      var $this = $(this);
      if ($this.data('table-intialized')) {
        return;
      };

      if ($this.is('[data-loaded]') && $this.find('thead tr').length === 1 ) {
        var $columnHeaders = $this.find('th');
        var $unsortableColumnHeaders = $this.find('th[data-unsortable]');
        var $unsortableColumnIndices = [];
        var missingDataMessage = $this.data('missing-data-message');
        $.each($unsortableColumnHeaders, function(i, header){ $unsortableColumnIndices.push($columnHeaders.index(header)) });
        var dataTableOptions = {
          paging: false,
          info: false,
          autoWidth: !($this.data('disable-auto-width') === ""),
          language: {
            "emptyTable": missingDataMessage
          },
          columnDefs: [
            {
              targets: 'report-column-nosort',
              orderable: false
            }
          ],
          aoColumnDefs: [
            {
              bSortable: false,
              aTargets: $unsortableColumnIndices
            }
          ]
        };
        if ($this.is('[data-sortable]')) {
          dataTableOptions['order'] = $this.data('default-sort') || [[0, 'asc']]
        } else {
          dataTableOptions['bSort'] = false;
        };
        $dataTable = $this.DataTable(dataTableOptions);
      };

      $this.find('.detail-view-trigger').on('click', function(event){
        $('.report-table tr').removeClass('detail-view');
        event.stopPropagation();
        $(event.target).closest('tr').addClass('detail-view');
        reportDetailEventListener();
      });

      $this.data('table-intialized', true);

      var filterClass = $this.data('filter-class');
      if (filterClass && $dataTable) {
        var $filterContainer = $('.' + filterClass);
        var $filters = $filterContainer.find('span');
        $filterContainer.on('click', function(e){
          var $filter = $(e.target);
          var filterValue = $filter.data('filter');
          filterValue = (filterValue == 'all') ? '' : filterValue;
          $filters.removeClass('active');
          $filter.addClass('active');
          $dataTable.search(filterValue).draw();
        });
        // Include anything that should be reset when table is filtered (e.g. checkboxes, states, etc.)
        $dataTable.on('draw', function(){
          $this.find('input[type=checkbox]').attr('checked', false);
        });
      };

    });
  };

  bindTables();

  $('body').on('table-rebind', bindTables);

  function reportDetailEventListener() {
    var $window = $(window);
    var $reportDetails = $('.report-table .report-detail-cell');
    $window.on("click.reportDetailOpen", function(event){
      if ( ($reportDetails.has(event.target).length == 0 && !$reportDetails.is(event.target)) || $(event.target).hasClass('hide-detail-view') ) {
        $('.report-table tr').removeClass('detail-view');
        $window.off('click.reportDetailOpen');
      };
    });
  };
});