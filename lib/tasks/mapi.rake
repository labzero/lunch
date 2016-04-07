namespace :mapi do

  desc 'Run the MAPI console.'
  task :console, [:environment] do |task, args|
    cli_args = []
    if args.environment
      cli_args << '-e' << args.environment
    end
    exec File.expand_path('../../../api/bin/console', __FILE__), *cli_args
  end

end