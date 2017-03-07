class MailerJob < ActiveJob::Base

  def perform(class_name, method, *args)
    klass = class_name.constantize
    raise "#{class_name} is not an ActionMailer::Base" unless klass < ActionMailer::Base
    klass.public_send(method.to_sym, *args).deliver_now
  end

end
