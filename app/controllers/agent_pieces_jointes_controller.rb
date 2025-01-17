# frozen_string_literal: true

class AgentPiecesJointesController < ApplicationController

  layout "agent"

  before_action :identification_agent, :eleve

  def create
    PieceJointe.create!(piece_jointe_params.merge(dossier_eleve: @eleve.dossier_eleve, etat: "soumis"))
    redirect_to "/agent/eleve/#{@eleve.identifiant}"
  end

  def update
    piece_jointe = PieceJointe.find(params[:id])
    piece_jointe.update!(piece_jointe_params.merge(dossier_eleve: @eleve.dossier_eleve, etat: "soumis"))
    redirect_to "/agent/eleve/#{@eleve.identifiant}"
  end

  private

  def piece_jointe_params
    params.require(:piece_jointe).permit({ fichiers: [] }, :piece_attendue_id)
  end

  def eleve
    @eleve ||= Eleve.find_by(identifiant: params[:eleve_id])
  end

end
