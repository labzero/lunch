class Cms::BaseObject
  attr_reader :cms, :cms_key, :revisions

  def initialize(member_id, request, cms_key, cms=nil)
    @cms_key = cms_key
    @cms = cms || ContentManagementService.new(member_id, request)
    raise ArgumentError, 'Failed to create a valid instance of `ContentManagementService`' unless @cms.present?
  end
end