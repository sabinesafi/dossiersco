# frozen_string_literal: true

module Configuration
  class OptionsPedagogiquesController < ApplicationController

    layout "configuration"

    before_action :identification_agent
    before_action :set_option_pedagogique, only: %i[edit update destroy]

    def index
      @mefs = Mef.where(etablissement: @agent_connecte.etablissement).includes(:options_pedagogiques)
      @options_pedagogiques = OptionPedagogique.where(etablissement: @agent_connecte.etablissement).order(:nom)
    end

    def liste
      @options_pedagogiques = OptionPedagogique.where(etablissement: @agent_connecte.etablissement).order(:nom)
    end

    def new
      @option_pedagogique = OptionPedagogique.new
      @mef = Mef.all
    end

    def edit
      @mef = Mef.all
    end

    def create
      @option_pedagogique = OptionPedagogique.new(option_pedagogique_params.merge(etablissement: agent_connecte.etablissement))

      if @option_pedagogique.save
        redirect_to configuration_options_pedagogiques_url, notice: t(".option_cree")
      else
        @option_pedagogique.errors.full_messages.each do |message|
          flash[:alert] = message
        end
        render :new
      end
    end

    def update
      if @option_pedagogique.update(option_pedagogique_params)
        flash[:notice] = t(".option_mise_a_jour")
        redirect_back(fallback_location: configuration_options_pedagogiques_url)
      else
        render :edit
      end
    end

    def destroy
      @option_pedagogique.destroy
      flash[:notice] = t(".option_supprimee")
      redirect_back(fallback_location: liste_configuration_options_pedagogiques_path)
    end

    def ajoute_option_au_mef
      option = OptionPedagogique.find(params[:option_pedagogique])
      mef = Mef.find(params[:id])
      mef_option = MefOptionPedagogique.find_or_create_by(option_pedagogique: option, mef: mef)
      mef_option.abandonnable = params[:abandonnable]
      mef_option.save
      redirect_to configuration_options_pedagogiques_path
    end

    def enleve_option_au_mef
      MefOptionPedagogique.find(params[:id]).destroy
      redirect_to configuration_options_pedagogiques_path
    end

    def definie_abandonnabilite
      mef_option = MefOptionPedagogique.find(params[:mef_option_pedagogique_id])
      mef_option.update(abandonnable: params[:abandonnable])
      head :ok
    end

    def definie_ouverte_inscription
      mef_option = MefOptionPedagogique.find(params[:mef_option_pedagogique_id])
      mef_option.update(ouverte_inscription: params[:ouverte_inscription])
      head :ok
    end

    private

    def set_option_pedagogique
      @option_pedagogique = OptionPedagogique.find(params[:id])
    end

    def option_pedagogique_params
      params.require(:option_pedagogique).permit(:libelle, :code_matiere, :code_matiere_6, :nom, :obligatoire, :groupe,
                                                 :explication, mef_ids: [])
    end

  end
end
