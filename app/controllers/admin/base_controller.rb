module Admin
  class BaseController < ApplicationController
    before_action :ensure_admin!
    layout "application"

    private

    def ensure_admin!
      authorize :admin, :access?
    end
  end
end
