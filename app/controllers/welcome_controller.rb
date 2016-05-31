class WelcomeController < ApplicationController

  skip_before_action :authenticate_user!, :check_terms
  around_action :skip_timeout_reset, only: [:session_status]

  layout 'external'

  def grid_demo

  end

  def details
    render text: get_revision || 'No REVISION found!'
  end

  def healthy
    begin
      redis_status = Resque.redis.ping == 'PONG'
    rescue Exception => e
      Rails.logger.error("Redis PING failed: #{e.message}")
      redis_status = false
    end

    begin
      db_status = ActiveRecord::Base.connection.active?
    rescue Exception => e
      Rails.logger.error("RDS PING failed: #{e.message}")
      db_status = false
    end

    begin
      mapi_status = MAPIService.new(request).ping
    rescue Exception => e
      Rails.logger.error("MAPI PING failed: #{e.message}")
      mapi_status = false
    end

    begin
      Resque.workers.each do |worker|
        worker.prune_dead_workers # helps ensure we have an accurate count
      end
      resque_status = Resque.workers.count > 0
    rescue Exception => e
      Rails.logger.error("Resque worker check failed: #{e.message}")
      resque_status = false
    end

    begin
      ldap_intranet_status = Devise::LDAP::Connection.admin('intranet').open do |ldap|
        ldap.search(filter: 'ou=FHLB-Accounts').present?
      end
    rescue Exception => e
      Rails.logger.error("LDAP Intranet check failed: #{e.message}")
      ldap_intranet_status = false
    end

    begin
      ldap_extranet_status = Devise::LDAP::Connection.admin('extranet').open do |ldap|
        ldap.search(filter: 'ou=eBiz').present?
      end
    rescue Exception => e
      Rails.logger.error("LDAP Extranet check failed: #{e.message}")
      ldap_extranet_status = false
    end

    begin
      rsa_status = false
      if Rails.env.production?
        agent_status = RSA::SecurID.agent_status
        rsa_status = true if agent_status && agent_status[:servers].select {|s| s[:active_address] }.present?
      end
    rescue Exception => e
      Rails.logger.error("RSA check failed: #{e.message}")
      rsa_status = false
    end

    render json: {
      revision: get_revision,
      bartertown: mapi_status, # MAPI
      beforetimes: db_status, # App DB
      masterblaster: resque_status, # Resque
      tomorrowmorrowland: redis_status, # Redis,
      madmax: ldap_intranet_status, # LDAP Intranet
      roadwarrior: ldap_extranet_status, # LDAP Extranet
      fury_road: rsa_status # RSA
    }
  end

  def session_status
    render json: {user_signed_in: user_signed_in?, logged_out_path: after_sign_out_path_for(nil)}
  end

  protected

  def get_revision
    revision = ENV['DEPLOY_REVISION']
    unless !revision || revision.empty?
      revision
    else
      false
    end
  end
end
