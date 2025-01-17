# frozen_string_literal: true

require "test_helper"

class AgentPiecesJointesControllerTest < ActionDispatch::IntegrationTest

  test "upload un fichier puis affiche un compte rendu du contenu" do
    admin = Fabricate(:admin)
    identification_agent(admin)
    piece_attendue = Fabricate(:piece_attendue)
    eleve = Fabricate(:dossier_eleve).eleve

    piece_jointe = fixture_file_upload("files/sample.png", "image/png")
    post agent_pieces_jointes_url, params: {
      piece_jointe: {
        fichiers: [piece_jointe],
        piece_attendue_id: piece_attendue.id
      },
      eleve_id: eleve.identifiant
    }

    assert_redirected_to "/agent/eleve/#{eleve.identifiant}"
  end

end
