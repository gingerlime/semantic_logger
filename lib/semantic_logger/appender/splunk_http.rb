require 'json'
# Splunk log appender using the Splunk HTTP(S) listener.
#
# Use the newer, faster and more complete JSON over HTTP interface for Splunk.
#
# To configure Splunk to receive log messages via this appender:
#   http://dev.splunk.com/view/event-collector/SP-CAAAE7F
#
# Example
#   SemanticLogger.add_appender(
#     appender: :splunk_http,
#     url:      'http://localhost:8080',
#     token:    '70CA900C-3D7E-42A4-9C79-7975D1C422A8'
#   )
class SemanticLogger::Appender::SplunkHttp < SemanticLogger::Appender::Http
  attr_accessor :source_type, :index

  # Create Splunk appender over persistent HTTP(S)
  #
  # Parameters:
  #   token: [String]
  #     Token created in Splunk for this HTTP Appender
  #     Mandatory.
  #
  #   source_type: [String]
  #     Optional: Source type to display in Splunk
  #
  #   index: [String]
  #     Optional: Name of a valid index for this message in Splunk.
  #
  #   url: [String]
  #     Valid URL to post to.
  #       Example: http://example.com
  #     To enable SSL include https in the URL.
  #       Example: https://example.com
  #       verify_mode will default: OpenSSL::SSL::VERIFY_PEER
  #
  #   application: [String]
  #     Name of this application to appear in log messages.
  #     Default: SemanticLogger.application
  #
  #   host: [String]
  #     Name of this host to appear in log messages.
  #     Default: SemanticLogger.host
  #
  #   compress: [true|false]
  #     Splunk supports HTTP Compression, enable by default.
  #     Default: true
  #
  #   ssl: [Hash]
  #     Specific SSL options: For more details see NET::HTTP.start
  #       ca_file, ca_path, cert, cert_store, ciphers, key, open_timeout, read_timeout, ssl_timeout,
  #       ssl_version, use_ssl, verify_callback, verify_depth and verify_mode.
  #
  #   level: [:trace | :debug | :info | :warn | :error | :fatal]
  #     Override the log level for this appender.
  #     Default: SemanticLogger.default_level
  #
  #   formatter: [Object|Proc]
  #     An instance of a class that implements #call, or a Proc to be used to format
  #     the output from this appender
  #     Default: Use the built-in formatter (See: #call)
  #
  #   filter: [Regexp|Proc]
  #     RegExp: Only include log messages where the class name matches the supplied.
  #     regular expression. All other messages will be ignored.
  #     Proc: Only include log messages where the supplied Proc returns true
  #           The Proc must return true or false.
  def initialize(token: nil, source_type: nil, index: nil,
                 url:, compress: true, ssl: {}, open_timeout: 2.0, read_timeout: 1.0, continue_timeout: 1.0,
                 level: nil, formatter: nil, filter: nil, application: nil, host: nil, &block)

    @source_type = source_type
    @index       = index

    super(url:   url, compress: compress, ssl: ssl, open_timeout: 2.0, read_timeout: open_timeout, continue_timeout: continue_timeout,
          level: level, formatter: formatter, filter: filter, application: application, host: host, &block)

    # Put splunk auth token in the header of every HTTP post.
    @header['Authorization'] = "Splunk #{token}"
  end

  # Returns [String] JSON to send to Splunk.
  #
  # For splunk format requirements see:
  #   http://dev.splunk.com/view/event-collector/SP-CAAAE6P
  def call(log, logger)
    h = SemanticLogger::Formatters::Raw.new.call(log, logger)
    h.delete(:time)
    message               = {
      source: logger.application,
      host:   logger.host,
      time:   log.time.utc.to_f,
      event:  h
    }
    message[:source_type] = source_type if source_type
    message[:index]       = index if index
    message.to_json
  end

end
