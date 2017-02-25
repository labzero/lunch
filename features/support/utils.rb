require 'logger'

def parallel_test_number
  ENV['TEST_ENV_NUMBER'] == '' ? 1 : ENV['TEST_ENV_NUMBER'].try(&:to_i)
end

def is_parallel_primary
  parallel_test_number == 1
end

def is_parallel_secondary
  !is_parallel_primary && parallel_test_number.present?
end

def is_parallel
  is_parallel_primary || is_parallel_secondary
end

def run_name
  [ENV['JOB_NAME'] || "Local Dev (#{`whoami`.strip})", ENV['BUILD_NUMBER'], parallel_test_number].compact.join('-')
end

def log(msg, logger: nil, level: Logger::INFO)
  logger ||= (Thread.current['cucumber.logger'] ||= (
    path = Dir.exists?('log') ? 'log/' : ''
    file = 'cucumber'
    file += ".#{parallel_test_number}" if is_parallel
    Logger.new(path + file + '.log')
  ))
  msg_lines = msg.split("\n")
  msg_lines.each do |line|
    logger.log(level) { line }
    STDOUT.puts line
  end
  STDOUT.flush
end

def port_retry
  tries ||= 3
  port = find_available_port
  yield port
rescue SupportingService::ServiceLaunchError => e
  tries = tries - 1
  if tries <= 0
    raise e
  else
    log "#{e.message}... retrying..."
    retry
  end
end

def find_available_port(port_list=nil)
  port_list ||= [0]
  shuffled_list = Array.wrap(port_list).shuffle.each
  begin
    try_port = shuffled_list.next
    server = TCPServer.new('127.0.0.1', try_port)
  rescue Errno::EADDRINUSE
    retry
  rescue StopIteration
    raise SupportingService::ServiceLaunchError.new('could not find free port')
  end
  server.addr[1]
ensure
  server.close if server
end

def check_service(service, port, host='127.0.0.1')
  pinger = Net::Ping::TCP.new host, port, 1
  now = Time.now
  while !pinger.ping
    if Time.now - now > 10
      service.kill
      raise SupportingService::ServiceLaunchError.new("#{service.name} failed to start")
    end
    log "pinging #{service.name} on #{host}:#{port}"
    sleep(1)
  end
end

class SupportingService

  class ServiceLaunchError < RuntimeError
  end

  attr_accessor :before_kill, :after_kill
  attr_reader :name, :cmd, :env, :forward_output, :kill_signal, :output_formatter

  def initialize(name, *cmd, env: {}, forward_output: false, kill_signal: 'INT', output_formatter: nil, **options)
    raise "`cmd` can't be empty" if cmd.empty?
    raise '`output_formatter` must respond to `call`' if output_formatter && !output_formatter.respond_to(:call)
    @name = name
    @cmd = cmd.dup.freeze
    @env = env.dup.freeze
    @forward_output = forward_output
    @output_formatter = output_formatter
    @kill_signal = kill_signal
    @fds = []
  end

  def before_kill=(proc)
    raise "`proc` must respond to `call`" unless proc.respond_to?(:call)
    @before_kill = proc
  end

  def after_kill=(proc)
    raise "`proc` must respond to `call`" unless proc.respond_to?(:call)
    @after_kill = proc
  end

  def run
    raise "can't `run` an already ran service" if launched?

    options = {in: :close}

    if forward_output
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      options[:out] = out_w.fileno
      options[:err] = err_w.fileno
      @fds << out_r << err_r
      forward_output_valid = forward_output.respond_to?(:write) && forward_output.respond_to?(:closed?)
      handle_service_output((forward_output_valid ? forward_output : STDOUT), out_r, err_r)
    else
      options[:out] = (out_w = File.open(File::NULL, 'w'))
      options[:err] = (err_w = File.open(File::NULL, 'w'))
    end

    pid = fork do
      exec(env, *cmd, options)
    end
    @process = Process.detach(pid)
    at_exit do
      self.kill
    end

    out_w.close
    err_w.close

    self
  end

  def launched?
    !!@process
  end

  def running?
    !!@process.alive? if launched?
  end

  def kill
    if running?
      self.before_kill.call if self.before_kill

      Process.kill(self.kill_signal, @process.pid) rescue Errno::ESRCH
      @process.value
      if @output_thread
        @output_thread.kill
        @output_thread.value
      end
      @fds.each { |fd| fd.close unless fd.closed? }

      self.after_kill.call if self.after_kill
    end
  end

  def pid
    @process.pid if launched?
  end

  protected

  def format_output(data)
    self.output_formatter ? self.output_formatter.call(data, self) : "[#{self.name}] #{data}"
  end

  def handle_service_output(output, *inputs)
    @output_thread = Thread.new do
      loop do
        ios = IO.select(inputs, nil, nil, 1)
        (ios || []).flatten.each do |io|
          if io.eof?
            inputs.delete(io)
          else
            data = io.gets # always consume the IO stream, even if we will discard the results
            output.write(self.format_output(data)) unless output.closed?
          end
        end
        Thread.pass
      end
    end
  end

end