class RenderLetterOfCreditPDFJob < RenderPDFJob
  def initialize_controller
    @controller = LettersOfCreditController.new
  end
end