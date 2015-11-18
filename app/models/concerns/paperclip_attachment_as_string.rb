module PaperclipAttachmentAsString
  extend ActiveSupport::Concern

  included do
    Paperclip::AttachmentRegistry.names_for(self).each do |name|
      self.send(:define_method, "#{name}_as_string") do
        string = nil
        Tempfile.open("#{self.class.name.parameterize}_#{name}", Rails.root.join('tmp')) do |f|
          begin
            self.send(name).copy_to_local_file(:original, f.path)
            string = f.read
          ensure
            f.unlink
          end
        end
        string
      end
    end
  end
end