class ApplicationController < ActionController::Base
  before_action :check_mfa_authenticated

  private

    # this check is extremely important, without this after doing login and before device accept (from mfa/index.html), user can go anywhere without mfa_authentication!
    def check_mfa_authenticated
      if current_user.present? && !current_user.mfa_access_token.blank? && !current_user.mfa_authenticated?
        sign_out(current_user)
        redirect_to root_url, notice: 'MFA Two Factor Authenication required'
      end
    end
  
  protected
      def after_sign_in_path_for(resource)
        request.env['omniauth.origin'] || stored_location_for(resource) || dashboard_index_path
      end
end
