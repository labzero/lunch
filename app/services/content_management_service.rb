class ContentManagementService
  attr_reader :api, :member_id, :request

  def initialize(member_id, request)
    @member_id = member_id
    @request = request
    @api = Prismic.api(url, access_token)
  end

  def content_by_uid(type, uid)
    begin
      api.get_by_uid(type, uid, ref: ref)
    rescue Prismic::Error => e
      Rails.logger.error("Prismic CMS error for fhlb_id `#{member_id}`, request_uuid `#{request.try(:uuid)}`: #{e.class.name}")
      Rails.logger.error e.backtrace.join("\n")
      return nil
    end
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
    @ref ||= if ENV['PRISMIC_REF']
      api.ref(ENV['PRISMIC_REF']).ref
    else
      api.master.ref
    end
  end

  def url
    @url ||= (ENV['PRISMIC_URL'] || config['url'])
  end
end