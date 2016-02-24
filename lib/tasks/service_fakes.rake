namespace :service_fakes do
  task enable: ['service_fakes:mds:enable', 'service_fakes:cal:enable', 'service_fakes:pi:enable']
  task disable: ['service_fakes:mds:disable', 'service_fakes:cal:disable', 'service_fakes:pi:disable']

  namespace :mds do
    desc 'Enable the fake Market Data Service'
    task :enable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:mds:enable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:mds, true)
    end

    desc 'Disable the fake Market Data Service'
    task :disable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:mds:disable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:mds, false)
    end
  end
  namespace :cal do
    desc 'Enable the fake Calendar Service'
    task :enable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:cal:enable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:cal, true)
    end

    desc 'Disable the fake Calendar Service'
    task :disable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:cal:disable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:cal, false)
    end
  end
  namespace :pi do
    desc 'Enable the fake Price Indications Service'
    task :enable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:pi:enable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:pi, true)
    end

    desc 'Disable the fake Price Indications Service'
    task :disable do
      require 'fhlb_member/services/fakes'
      raise '`rake service_fakes:pi:disable` was unsuccessful.' unless FhlbMember::Services::Fakes.use_fake_service(:pi, false)
    end
  end
end