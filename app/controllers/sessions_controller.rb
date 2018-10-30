class SessionsController < Devise::SessionsController
  skip_before_action :check_mfa_authenticated

  def create
      resource = warden.authenticate!(auth_options)
      if resource.mfa_access_token.present?
            resource.update_attribute(:mfa_authenticated, false)
            acceptto = Acceptto::Client.new(Rails.configuration.mfa_app_uid, Rails.configuration.mfa_app_secret,"#{request.protocol + request.host_with_port}/auth/mfa/callback")
            @channel = acceptto.authenticate(resource.mfa_access_token, "Acceptto is wishing to authorize", "Login", cookies, {:ip_address => request.ip, :remote_ip_address => request.remote_ip})
            session[:channel] = @channel
            callback_url = "#{request.protocol + request.host_with_port}/auth/mfa/check"
            redirect_url = "#{Rails.configuration.mfa_site}/mfa/index?channel=#{@channel}&callback_url=#{callback_url}"
            return redirect_to redirect_url
      else
            set_flash_message(:notice, :signed_in) if is_navigational_format?
            sign_in(resource_name, resource)
            respond_with(resource, location:root_path) do |format|
              format.json { render json: resource.as_json(root: false).merge(success: true), status: :created }
            end
      end

      rescue OAuth2::Error => ex # User has deleted their access token on M2M server
      resource.update_attribute(:mfa_access_token, nil)
      redirect_to root_path, notice: "You have unauthorized MFA access to Acceptto, you will need to Authorize MFA again."
  end

  def mfa_callback
      if params[:error].present?
         return redirect_to root_url, notice: params[:error]
      end

      if params[:access_token].blank?
          return redirect_to root_url, notice: 'Invalid parameters!'
      end

      if current_user.nil?
          sign_out(current_user)
          return redirect_to root_url, notice: 'Your session timed out, please sign-in again!'
      end

      current_user.update_attribute(:mfa_access_token, params[:access_token])
      current_user.update_attribute(:mfa_authenticated, true)
      return redirect_to root_url, notice: 'Enabling Multi Factor Authentication was successful!'
  end


  def mfa_check
      if current_user.nil?
          redirect_to root_url, notice: 'MFA Two Factor Authentication request timed out with no response.'
      end

      acceptto = Acceptto::Client.new(Rails.configuration.mfa_app_uid, Rails.configuration.mfa_app_secret, "#{request.protocol + request.host_with_port}/auth/mfa/callback")
      status = acceptto.mfa_check(current_user.mfa_access_token,params[:channel])

      if status == 'approved'
          current_user.update_attribute(:mfa_authenticated, true)
          redirect_to after_sign_in_path_for(current_user), notice: 'MFA Two Factor Authentication request was accepted.'
      elsif status == 'rejected'
          current_user.update_attribute(:mfa_authenticated, false)
          sign_out(current_user)
          redirect_to root_url, notice: 'MFA Two Factor Authentication request was declined.'
      else
          redirect_to root_url, notice: "MFA Two Factor Authentication status is: #{status}"
      end
  end
end