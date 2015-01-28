class MessageService

  def corporate_communications
    # TODO: hit some endpoint or endpoints to retrieve/construct an object similar to the fake one below.
    begin
      data = JSON.parse(File.read(File.join(Rails.root, 'db', 'service_fakes', 'corporate_communications.json')))
    rescue JSON::ParserError => e
      Rails.logger.warn("MessageService.corporate_communications encountered a JSON parsing error: #{e}")
      return nil
    end
    data.each_with_index do |message, index|
      message['date'] = message['date'].to_date
      data[index] = message.with_indifferent_access
    end
  end

end