class LandingController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to root_path if authenticated?
  end
end
