module StreamingHelper
  def stream_attachment_processor(response)
    lambda do |status, headers, body|
      status = status.to_i
      if status == 200
        ['Content-Type', 'Content-Disposition', 'Content-Length'].each do |key|
          header_value = headers[key]
          response.headers[key] = header_value if header_value
        end
        response.headers['Cache-Control'] = 'no-cache'
        response.body = body
      else
        response.status = status
        raise ActionController::RoutingError.new('Not Found') if status == 404
        raise StandardError.new('Stream Error') if status >= 500
      end
    end
  end
end