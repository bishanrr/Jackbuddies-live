module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:edit, :update, :approve, :deny]

    def index
      authorize User
      @pending_users = User.pending.order(:created_at)
      @users = User.order(created_at: :desc)
    end

    def edit
      authorize @user
    end

    def update
      authorize @user
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      authorize @user, :approve?
      @user.update!(status: :approved, approved_at: Time.current, approved_by: current_user, denial_reason: nil, denied_at: nil, denied_by: nil)
      redirect_to admin_users_path, notice: "User approved."
    end

    def deny
      authorize @user, :deny?
      @user.update!(status: :denied, denied_at: Time.current, denied_by: current_user, denial_reason: params[:denial_reason].presence || "Denied by admin")
      redirect_to admin_users_path, notice: "User denied."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:display_name, :email, :role, :status)
    end
  end
end
