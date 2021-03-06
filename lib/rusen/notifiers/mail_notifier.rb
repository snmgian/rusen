require_relative 'base_notifier'

begin
  require 'mail'
rescue LoadError
  puts <<-MESSAGE
  [Rusen Error] To use Mail notifier add this to your Gemfile:
    gem 'mail'
  MESSAGE
  raise
end

module Rusen
  module Notifiers

    class MailNotifier < BaseNotifier

      def self.identification_symbol
        :mail
      end

      def initialize(settings)
        super(settings)

        if @settings && @settings.smtp_settings.any?
          smtp_settings = @settings.smtp_settings

          Mail.defaults do
            delivery_method :smtp, smtp_settings
          end
        end
      end

      def notify(notification)
        @notification = notification
        @sessions     = get_sessions(@notification)

        options = email_options.dup
        options.merge!({:body => build_body})
        mail = Mail.new do
          from      options[:from]
          to        options[:to]
          reply_to  options[:reply_to]
          cc        options[:cc]
          bcc       options[:bcc]
          subject   options[:subject]
          html_part do
            content_type "text/html; charset=#{options[:charset]}"
            body    options[:body]
          end
        end

        # We need to ignore all the exceptions thrown by MailNotifier#notify.
        mail.deliver!
      rescue Exception => exception
        handle_notification_exception(exception)
      end

      private

      def email_options
        {
          :to => @settings.exception_recipients,
          :charset => 'UTF-8',
          :from => @settings.sender_address,
          :subject => email_subject
        }
      end

      def email_subject
        @settings.email_prefix + "#{@notification.exception.class}: #{@notification.exception.message}"
      end

      def build_body
        template_path = File.expand_path('../../templates/email_template.html.erb', __FILE__)

        template = File.open(template_path).read
        rhtml = ERB.new(template, nil, '-')
        rhtml.result(binding)
      end

    end

  end

end