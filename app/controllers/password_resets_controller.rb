class PasswordResetsController < ApplicationController
  SECRET_SESSION_KEY = :password_reset_secret_verified_at
  SECRET_TTL = 15.minutes

  skip_before_action :authenticate_user!
  skip_before_action :ensure_approved_user!

  def new
  end

  def verify
    if params[:secret_code].to_s == secret_code
      session[SECRET_SESSION_KEY] = Time.current.to_i
      redirect_to edit_password_reset_path, notice: "Secret code accepted. You can change your password now."
    else
      flash.now[:alert] = "Invalid secret code."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return if secret_code_verified?

    redirect_to new_password_reset_path, alert: "Enter the secret code before resetting your password."
  end

  def update
    unless secret_code_verified?
      redirect_to new_password_reset_path, alert: "Enter the secret code before resetting your password."
      return
    end

    @user = User.find_by(email: params[:email].to_s.strip.downcase)
    if @user.blank?
      flash.now[:alert] = "No user found for that email."
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.update(password_params)
      session.delete(SECRET_SESSION_KEY)
      redirect_to new_user_session_path, notice: "Password updated. You can sign in now."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def secret_code_verified?
    verified_at = session[SECRET_SESSION_KEY].to_i
    verified_at.positive? && Time.at(verified_at) >= SECRET_TTL.ago
  end

  def secret_code
    ENV.fetch("PASSWORD_RESET_SECRET_CODE", "nhy6bgt5")
  end
end
