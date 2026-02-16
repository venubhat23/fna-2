class CustomFailure < Devise::FailureApp
  def respond
    if request.respond_to?(:flash) && is_flashing_format?
      if http_auth?
        http_auth
      else
        flash.now[:alert] = "Invalid Login or password."
        redirect
      end
    else
      super
    end
  end
end
