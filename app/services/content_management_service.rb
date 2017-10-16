class ContentManagementService
  attr_reader :api, :member_id, :request

  DOCUMENT_MAPPING = {
    credit_guide: {
      type: 'guide',
      uid: 'credit'
    },
    collateral_guide: {
      type: 'guide',
      uid: 'collateral'
    }
  }.freeze

  def initialize(member_id, request)
    @member_id = member_id
    @request = request
    @api = Prismic.api(url, access_token)
  end

  def get_document(cms_key)
    cms_info = DOCUMENT_MAPPING[cms_key]
    raise ArgumentError, 'Invalid `cms_key`' if cms_info.blank?
    begin
      api.get_by_uid(cms_info[:type], cms_info[:uid], ref: ref)
    rescue Prismic::Error => e
      Rails.logger.error("Prismic CMS error for fhlb_id `#{member_id}`, request_uuid `#{request.try(:uuid)}`: #{e.class.name}")
      Rails.logger.error e.backtrace.join("\n")
      return nil
    end
  end

  def get_pdf_url(cms_key)
    fragments = get_document(cms_key).try(:fragments)
    if fragments
      fragments['pdf'].try(:url)
    end
  end

  def get_slices_by_type(cms_key, slice_type)
    document = get_document(cms_key)
    if document
      document.get_slice_zone("#{DOCUMENT_MAPPING[cms_key][:type]}.body").slices.select {|slice| slice.slice_type == slice_type.to_s }
    end
  end

  def get_date(cms_key, date_field)
    document = get_document(cms_key)
    if document
      document.get_date("#{DOCUMENT_MAPPING[cms_key][:type]}.#{date_field}").try(:value).try(:to_date)
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
      api.ref(ENV['PRISMIC_REF']).try(:ref) || api.master.ref
    else
      api.master.ref
    end
  end

  def url
    @url ||= (ENV['PRISMIC_URL'] || config['url'])
  end
end