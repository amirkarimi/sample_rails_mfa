class DashboardController < ApplicationController
  
  before_action :authenticate_user!
  
  def index
  end
  
  def disable_mfa
    current_user.update_attribute(:mfa_access_token, nil)
    return redirect_to dashboard_index_url, notice: 'Multi factor authentication disabled for user!'
  end
end
