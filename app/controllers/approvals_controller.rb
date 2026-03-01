class ApprovalsController < ApplicationController
  skip_before_action :ensure_approved_user!

  def show
    authorize :approval, :show?
  end
end
