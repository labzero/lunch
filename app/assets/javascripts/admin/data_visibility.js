$(function() {
  $selectMemberForm = $('.data-visibility-select-member');
  $selectMemberForm.find('select').on('change', function(e) {
    $selectMemberForm.submit();
  });
});