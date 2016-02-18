namespace :flipper do
  desc 'Seeds the flipper feature set.'
  task :seed, [:seed_file] => [:environment] do |t, args|
    seed_file = args.seed_file || Rails.root.join('db', 'features.json')

    flipper = Rails.application.flipper
    features = JSON.parse(File.read(seed_file))
    old_features = flipper.features.collect(&:name)

    (features - old_features).each do |name|
      flipper[name].disable
    end

    (old_features - features).each do |name|
      flipper.adapter.remove(flipper[name])
    end
  end
  namespace :feature do
    desc 'Enables a feature for the supplied actor, or all actors if none is supplied'
    task :enable, [:feature, :actor] => [:environment] do |t, args|
      raise ArgumentError.new('A feature is required.') unless args.feature
      actor = FhlbMember::FlipperActor.wrap(args.actor) if args.actor
      feature = Rails.application.flipper[args.feature]
      if actor
        feature.enable_actor(actor)
      else
        feature.enable
      end
    end

    desc 'Enable all *known* features for the supplied actor'
    task :enable_all, [:actor] => [:environment] do |t, args|
      raise ArgumentError.new('An actor is required.') unless args.actor
      actor = FhlbMember::FlipperActor.wrap(args.actor)
      Rails.application.flipper.features.each do |feature|
        feature.enable_actor(actor)
      end
    end

    desc 'Disables a feature for the supplied actor, or all actors if none is supplied'
    task :disable, [:feature, :actor] => [:environment] do |t, args|
      raise ArgumentError.new('A feature is required.') unless args.feature
      actor = FhlbMember::FlipperActor.wrap(args.actor) if args.actor
      feature = Rails.application.flipper[args.feature]
      if actor
        feature.disable_actor(actor)
      else
        feature.disable
      end
    end

    desc 'Disable all *known* features for the supplied actor'
    task :disable_all, [:actor] => [:environment] do |t, args|
      raise ArgumentError.new('An actor is required.') unless args.actor
      actor = FhlbMember::FlipperActor.wrap(args.actor)
      Rails.application.flipper.features.each do |feature|
        feature.disable_actor(actor)
      end
    end
  end
end