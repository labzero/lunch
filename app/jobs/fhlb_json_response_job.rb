class FhlbJsonResponseJob < FhlbJob

  def initialize(*args, &block)
    # Run the alias method chain on the eigenclass to modify our subclasses perform. This should always be done first.
    class << self
      alias_method_chain :perform, :json_result
    end

    super
  end
  
  def perform_with_json_result(*args, &block)
    results = perform_without_json_result(*args, &block)
    raise "There has been an error and #{self.class.name}#perform has encountered nil. Check error logs." if results.nil?
    return if job_status.canceled?

    file = StringIOWithFilename.new(results.to_json)
    file.content_type = 'application/json'
    file.original_filename = "results.json"
    return if job_status.canceled?

    job_status.result = file
    job_status.no_download = true
    job_status.save!
    results
  end

end