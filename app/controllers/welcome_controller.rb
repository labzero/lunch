class WelcomeController < ApplicationController

  skip_before_action :authenticate_user!

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

    render json: {
      revision: get_revision,
      bartertown: mapi_status, # MAPI
      beforetimes: db_status, # App DB
      masterblaster: resque_status, # Resque
      tomorrowmorrowland: redis_status # Redis
    }
  end

  protected

  def get_revision
    revision = `cat ./REVISION 2>/dev/null`.strip
    unless revision.empty?
      revision
    else
      false
    end
  end
end
