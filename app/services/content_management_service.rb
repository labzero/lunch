class ContentManagementService
  attr_reader :api, :member_id, :request

  def initialize(member_id, request)
    @member_id = member_id
    @request = request
    @api = Prismic.api(url, access_token)
  end

  def content_by_uid(type, uid)
    api.get_by_uid(type, uid, ref: ref)
  end

  def get_pdf_url(type_name, uid)
    fragments = content_by_uid(type_name, uid).try(:fragments)
    if fragments
      fragments['pdf'].try(:url)
    end
  end

  private

  def access_token
    @access_token ||= (ENV['PRISMIC_ACCESS_TOKEN'] || config['token'])
  end

  def config
    @config ||= YAML.load(ERB.new(File.new(Rails.root + "config/prismic.yml").read).result)
  end

  def ref
    @ref ||= (api.ref(ENV['PRISMIC_REF']) || api.master).ref
  end

  def url
    @url ||= (ENV['PRISMIC_URL'] || config['url'])
  end
end