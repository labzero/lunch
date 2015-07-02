$(function() {

  function bindTables() {
    $('.report-table').each(function() {
      var $this = $(this);

      if ($this.data('table-intialized')) {
        return;
      };

      if ($this.is('[data-sortable]')) {
        var $columnHeaders = $this.find('th');
        var $unsortableColumnHeaders = $this.find('th[data-unsortable]');
        var $unsortableColumnIndices = [];
        var missingDataMessage = $this.data('missing-data-message');
        $.each($unsortableColumnHeaders, function(i, header){ $unsortableColumnIndices.push($columnHeaders.index(header)) });
        $this.DataTable({
          paging: false,
          info: false,
          searching: false,
          order: $this.data('default-sort') || [[0, 'asc']],
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
        });
      }

      $this.find('.detail-view-trigger').on('click', function(event){
        $('.report-table tr').removeClass('detail-view');
        event.stopPropagation();
        $(event.target).closest('tr').addClass('detail-view');
        reportDetailEventListener();
      });

      $this.data('table-intialized', true);
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