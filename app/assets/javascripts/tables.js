$(function() {
  $('.report-table[data-sortable]').each(function(ele) {
    var $this = $(this);
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
      })
  });
}); 