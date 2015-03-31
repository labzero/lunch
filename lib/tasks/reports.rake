namespace :reports do
  namespace :advances do
    desc 'Generates an Advances PDF'
    task :pdf, [:member_id]=> [:environment] do |task, args|
      pdf = RenderReportPDFJob.new.perform(args.member_id, 'advances_detail')
      pdf_filename = Rails.root.join('tmp', "advances-#{args.member_id}-#{Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}.pdf")
      File.write(pdf_filename, pdf, mode: 'wb')
      STDOUT.puts pdf_filename
      %x{open #{pdf_filename}}
    end
  end
end