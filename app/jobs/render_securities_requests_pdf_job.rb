class RenderSecuritiesRequestsPDFJob < RenderPDFJob
  def initialize_controller
    @controller = SecuritiesController.new
  end

  def render_footer_html
    controller.instance_variable_set(:@footer_label,
      case controller.params[:kind]
      when 'pledge_release'
        I18n.t('securities.requests.view.pledge_release.footer')
      when 'safekept_release'
        I18n.t('securities.requests.view.safekept_release.footer')
      when 'pledge_intake'
        I18n.t('securities.requests.view.pledge_intake.footer')
      when 'safekept_intake'
        I18n.t('securities.requests.view.safekept_intake.footer')
      when 'pledge_transfer'
        I18n.t('securities.requests.view.pledge_transfer.footer')
      when 'safekept_transfer'
        I18n.t('securities.requests.view.safekept_transfer.footer')
      end
    )
    super
  end
end