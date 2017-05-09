require "rack_request_logger/version"
require 'colorize'

MID_LINE = "├─".light_white
END_LINE = "└─".light_white

class RackRequestLogger
  def initialize(app, logger)
    @app = app
    @logger = logger
  end

  def call(env)
    headers = env.select {|k,v| k.start_with? 'HTTP_'}
    .map {|pair| [pair[0].sub(/^HTTP_/, ''), pair[1]].join(": ")}
    .sort

    req = Rack::Request.new(env)

    body = parse_body(req.body)

    @logger.info ""
    @logger.info "  REQUEST".cyan
    print_lines [
      "Method   #{req.request_method}",
      "URL      #{req.url}",
      "Headers",
      headers,
      "Params",
      body
    ]
    @logger.info ""

    req.body.rewind
    @app.call(env).tap do |response|
      status, headers, body = response

      @logger.info ""
      @logger.info "  RESPONSE".cyan
      print_lines [
        "Response Code #{status}",
        "Headers",
        headers.map { |k,v| "#{k}: #{v}" },
        "Response",
        parse_body(body)
      ]
      @logger.info ""
    end
  end

  def print_lines(lines, indent=2)
    lines.each do |line|
      if line.kind_of?(Array)
        print_lines(line, indent + indent)
        next
      end
      prefix = MID_LINE
      prefix = END_LINE if line.equal?(lines.last)
      indention = " " * indent
      @logger.info "#{indention}#{prefix} #{line}"
    end
  end

  def parse_body(body)
    data = []
    body.each do |line|
      data << line_to_json(line)
    end

    data
  end

  def line_to_json(line)
    JSON.parse(line) rescue line
  end
end
