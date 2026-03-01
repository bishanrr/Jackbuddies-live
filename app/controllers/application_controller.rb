class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :set_current_season
  before_action :ensure_approved_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_season, :seasons_for_tabs, :admin?

  rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

  protected

  def after_sign_in_path_for(resource)
    return awaiting_approval_path unless resource.approved?

    home_path
  end

  def after_sign_up_path_for(resource)
    return awaiting_approval_path unless resource.approved?

    dashboard_path
  end

  def after_inactive_sign_up_path_for(_resource)
    awaiting_approval_path
  end

  def admin?
    user_signed_in? && current_user.admin?
  end

  def current_season
    @current_season
  end

  def seasons_for_tabs
    @seasons_for_tabs ||= Season.order(year: :desc)
  end

  private

  def set_current_season
    return unless user_signed_in?

    selected_id = params[:season_id].presence || session[:season_id]
    @current_season = Season.find_by(id: selected_id) || Season.order(year: :desc).first
    session[:season_id] = @current_season&.id
  end

  def ensure_approved_user!
    return unless user_signed_in?
    return if current_user.approved? || devise_controller? || request.path == awaiting_approval_path

    redirect_to awaiting_approval_path, alert: "Awaiting admin approval"
  end

  def handle_unauthorized
    redirect_back fallback_location: dashboard_path, alert: "You are not authorized for this action."
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:display_name])
  end
end
