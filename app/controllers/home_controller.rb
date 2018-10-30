class HomeController < ApplicationController
  
  skip_before_action :check_mfa_authenticated
  
  def index
  end
end
