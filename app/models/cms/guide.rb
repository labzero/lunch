class Cms::Guide
  attr_reader :cms, :guide_type

  def initialize(member_id, request, guide_type, cms=nil)
    @guide_type = guide_type
    @cms = cms || ContentManagementService.new(member_id, request)
    raise ArgumentError, 'Failed to create a valid instance of `ContentManagementService`' unless @cms.present?
  end

  def revisions
    revisions = []
    slices = cms.get_slices_by_type(guide_type, 'revision')
    slices.each { |slice| revisions <<  Revision.new(slice) }
    revisions.sort_by{ |revision| revision.last_updated }.reverse
  end

  def last_revised_date
    cms.get_date(guide_type, 'last_revised_date')
  end

  class Revision
    attr_reader :last_updated, :revision_list

    def initialize(slice)
      @last_updated = slice.non_repeat['revision_date'].value.to_date
      @revision_list = CGI.unescape_html(slice.as_html).squish.gsub(/<br(?:\s*\/)?>/, '').html_safe
    end
  end
end