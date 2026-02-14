class AccountController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    case params[:section]
    when "profile"
      if @user.update(profile_params)
        redirect_to account_path, notice: "Profile updated!"
      else
        render :show, status: :unprocessable_entity
      end
    when "password"
      if @user.update(password_params)
        redirect_to account_path, notice: "Password updated!"
      else
        render :show, status: :unprocessable_entity
      end
    when "notifications"
      if @user.update(notification_params)
        redirect_to account_path, notice: "Notification preferences updated!"
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def profile_params
    params.expect(user: [:name, :email_address, :time_zone])
  end

  def password_params
    params.expect(user: [:password, :password_confirmation])
  end

  def notification_params
    params.expect(user: [:notification_email])
  end
end
