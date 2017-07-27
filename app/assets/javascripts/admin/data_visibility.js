$(function() {
  $selectMemberForm = $('.data-visibility-select-member');
  $selectMemberForm.find('select').on('change', function(e) {
    $selectMemberForm.submit();
  });

  $dataVisibilityForm = $('.data-visibility-flags-form');
  $dataVisibilityForm.find('td input[type="checkbox"]').on('change', function(e) {
    $(this).parents('tr').toggleClass('data-source-disabled');
  });
});