class DashboardController < ApplicationController

  def index
    @previous_activity = [
        [t('dashboard.previous_activity.overnight_vrc'), 44503000, DateTime.new(2014,9,3)],
        [t('dashboard.previous_activity.overnight_vrc'), 39097000, DateTime.new(2014,9,2)],
        [t('dashboard.previous_activity.overnight_vrc'), 37990040, DateTime.new(2014,8,12)],
        [t('dashboard.previous_activity.overnight_vrc'), 39282021, DateTime.new(2014,2,14)]
    ]

  end



end