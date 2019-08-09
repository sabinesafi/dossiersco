# frozen_string_literal: true

require "test_helper"

class ImportElevesTest < ActiveSupport::TestCase

  include ActionDispatch::TestProcess::FixtureFile

  test "enregistre les données élèves" do
    etablissement = Fabricate(:etablissement)
    eleve = Fabricate(:eleve, identifiant: "070832327JA")
    dossier = Fabricate(:dossier_eleve, eleve: eleve)

    fichier_xml = fixture_file_upload("files/eleves_avec_adresse_simple.xml")
    tache = Fabricate(:tache_import, type_fichier: "nomenclature", fichier: fichier_xml, etablissement: etablissement)

    assert_nothing_raised do
      ImportEleves.new.perform(tache)
      dossier.reload
      assert_equal "10210001110", dossier.mef_an_dernier
      assert_equal "4 D", dossier.division_an_dernier
      assert_equal "3 A", dossier.division
    end
  end

end