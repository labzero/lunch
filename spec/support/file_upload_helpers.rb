module FileUploadHelpers
  def file_upload(path, mime_type)
    ActionDispatch::Http::UploadedFile.new({
      :tempfile => File.new(path),
      :type => mime_type
    })
  end

  def excel_fixture_file_upload(filename)
    file_upload(File.join(Rails.root, 'spec', 'fixtures', filename), 'application/vnd.ms-excel')
  end
end