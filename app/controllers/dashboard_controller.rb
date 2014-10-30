class DashboardController < ApplicationController

  def index
    @previous_activity = [
        ['Overnight VRC Open', '$44,503,000', 'SEPT 3, 2014'],
        ['Overnight VRC Open', '39,097,000', 'SEPT 2, 2014'],
        ['Overnight VRC Open', '37,990,040', 'AUG 12, 2014'],
        ['Overnight VRC Open', '39,282,021', 'FEB 14, 2014']
    ]

  end



end