module Admin
  class DataImportsController < BaseController
    def index
      @command = "bin/rails data:import_ipl_2025"
    end

    def create
      unless Rails.env.development?
        redirect_to admin_data_imports_path(season_id: current_season&.id), alert: "Run `bin/rails data:import_ipl_2025` from the terminal."
        return
      end

      result = Imports::Ipl2025Importer.new.call
      redirect_to admin_data_imports_path(season_id: current_season&.id), notice: "Import complete. #{result.summary}"
    rescue StandardError => e
      redirect_to admin_data_imports_path(season_id: current_season&.id), alert: "Import failed: #{e.message}"
    end
  end
end
