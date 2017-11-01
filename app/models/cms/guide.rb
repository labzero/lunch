class Cms::Guide < Cms::BaseObject
  attr_reader :revisions

  def revisions
    @revisions ||= (
      revisions = []
      slices = cms.get_slices_by_type(cms_key, 'revision') || []
      slices.each { |slice| revisions <<  Revision.new(slice) }
      revisions.sort_by{ |revision| revision.last_updated }.reverse
    )
  end

  def last_revised_date
    revisions.sort_by{ |revision| revision.last_updated }.reverse.first.try(:last_updated)
  end

  class Revision
    attr_reader :last_updated, :revision_list

    def initialize(slice)
      @last_updated = slice.non_repeat['revision_date'].value.to_date
      @revision_list = CGI.unescape_html(slice.as_html).squish.gsub(/<br(?:\s*\/)?>/, '').html_safe
    end
  end
end