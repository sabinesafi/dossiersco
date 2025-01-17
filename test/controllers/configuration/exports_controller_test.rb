# frozen_string_literal: true

require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest

  test "#export-siecle" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    resp = Fabricate(:resp_legal, email: "")
    dossier_eleve = Fabricate(:dossier_eleve,
                              etablissement: admin.etablissement,
                              resp_legal: [resp])

    resp = Fabricate(:resp_legal, email: nil)
    dossier_eleve = Fabricate(:dossier_eleve,
                              etablissement: admin.etablissement,
                              resp_legal: [resp])

    # resp = Fabricate(:resp_legal, communique_info_parents_eleves: nil)
    # dossier_eleve = Fabricate(:dossier_eleve,
    #                           etablissement: admin.etablissement,
    #                           resp_legal: [resp])

    # resp = Fabricate(:resp_legal, profession: nil)
    # dossier_eleve = Fabricate(:dossier_eleve,
    #                           etablissement: admin.etablissement,
    #                           resp_legal: [resp])

    resp = Fabricate(:resp_legal)
    dossier_eleve = Fabricate(:dossier_eleve,
                              etablissement: admin.etablissement,
                              resp_legal: [resp])
    3.times do
      resp = Fabricate(:resp_legal)
      dossier_eleve = Fabricate(:dossier_eleve,
                                etablissement: admin.etablissement,
                                resp_legal: [resp])
      option = Fabricate(:option_pedagogique, nom: "un super nom d'option un peu long", obligatoire: "F", code_matiere: "ALGEV")
      dossier_eleve.options_pedagogiques << option
    end

    resp = Fabricate(:resp_legal, enfants_a_charge: 2)
    Fabricate(:dossier_eleve,
              mef_destination: nil,
              etablissement: admin.etablissement,
              resp_legal: [resp])

    get export_siecle_configuration_exports_path(xml_only: true)

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    xsd = Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)
    assert_equal [], xsd.validate(xml)
  end

  test "L'adresse est renseignée dans l'export siècle" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    resp = Fabricate(:resp_legal,
                     adresse: "3 rue de test",
                     code_postal: "75000",
                     ville: "Ville de test",
                     pays: "FRA")
    Fabricate(:dossier_eleve,
              etablissement: admin.etablissement,
              resp_legal: [resp])
    %i[adresse code_postal ville pays].each do |partie_du_tag_adresse|
      resp_incomplet = Fabricate(:resp_legal,
                                 adresse: "adresse a ne pas afficher",
                                 code_postal: "75001",
                                 ville: "Ville a ne pas afficher",
                                 pays: "XXX")
      resp_incomplet[partie_du_tag_adresse] = nil
      Fabricate.build(:dossier_eleve,
                      etablissement: admin.etablissement,
                      resp_legal: [resp_incomplet])
    end

    get export_siecle_configuration_exports_path(xml_only: true)

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    xsd = Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)
    assert_equal [], xsd.validate(xml)
    assert_match "3 rue de test", response.body
    assert_match "75000", response.body
    assert_match "Ville de test", response.body
    assert_match "100", response.body
    assert_no_match "adresse a ne pas afficher", response.body
    assert_no_match "75001", response.body
    assert_no_match "Ville a ne pas afficher", response.body
    assert_no_match "XXX", response.body
  end

  test "L'INE est renseigné dans l'ID_NATIONAL" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    eleve = Fabricate(:eleve)
    resp_legal = Fabricate(:resp_legal)
    dossier = Fabricate(:dossier_eleve, eleve: eleve, resp_legal: [resp_legal], etablissement: admin.etablissement)

    get export_siecle_configuration_exports_path(xml_only: true)

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_match dossier.eleve.identifiant, xml.css("ID_NATIONAL").text
  end

  test "Pour une naissance à l'étranger, la commune est renseignée sous forme de texte" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    eleve = Fabricate(:eleve, ville_naiss: "KINSHASA", pays_naiss: "324")
    dossier = Fabricate(:dossier_eleve,
                        eleve: eleve,
                        etablissement: admin.etablissement,
                        mef_destination: Fabricate(:mef, etablissement: admin.etablissement))

    get export_siecle_configuration_exports_path(xml_only: true)

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_match dossier.eleve.pays_naiss,  xml.css("CODE_PAYS").text
    assert_match dossier.eleve.ville_naiss, xml.css("VILLE_NAISS").text
  end

  test "export uniquement pour l'INE saisi" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    resp = Fabricate(:resp_legal,
                     adresse: "3 rue de test",
                     code_postal: "75000",
                     ville: "Ville de test",
                     pays: "FRA")
    autre_resp = Fabricate(:resp_legal,
                           adresse: "8 rue de test",
                           code_postal: "75000",
                           ville: "Ville de test",
                           pays: "FRA")
    dossier = Fabricate(:dossier_eleve,
                        etablissement: admin.etablissement,
                        resp_legal: [resp])
    Fabricate(:dossier_eleve,
              etablissement: admin.etablissement,
              resp_legal: [autre_resp])

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_equal 1, xml.xpath("//ELEVE").count
  end

  test "exporte le CODE_MODALITE_ELECT" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    mef = Fabricate(:mef)
    option = Fabricate(:option_pedagogique)
    Fabricate(:mef_option_pedagogique, mef: mef, option_pedagogique: option, code_modalite_elect: "F")
    dossier = Fabricate(:dossier_eleve,
                        etablissement: admin.etablissement,
                        mef_destination: mef,
                        options_pedagogiques: [option])

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_equal "F", xml.xpath("//CODE_MODALITE_ELECT").text
  end

  test "exporte O comme valeur par défaut de CODE_MODALITE_ELECT" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    mef = Fabricate(:mef)
    option = Fabricate(:option_pedagogique)
    Fabricate(:mef_option_pedagogique, mef: mef, option_pedagogique: option, code_modalite_elect: nil)
    dossier = Fabricate(:dossier_eleve,
                        etablissement: admin.etablissement,
                        mef_destination: mef,
                        options_pedagogiques: [option])

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_equal "O", xml.xpath("//CODE_MODALITE_ELECT").text
  end

  test "utilise le 11e caractère du mef_an_dernier comme TYPE_MEF dans le fichier d'export" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    dossier = Fabricate(:dossier_eleve, etablissement: admin.etablissement, mef_an_dernier: "12345678009")

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    assert_equal "9", xml.xpath("//TYPE_MEF").text
  end

  test "retourne les options dans l'ordre de leur RANG_OPTION, suivi des options facultatives" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    mef = Fabricate(:mef)
    option_facultative = Fabricate(:option_pedagogique, code_matiere_6: "033333")
    option_de_rang_2 = Fabricate(:option_pedagogique, code_matiere_6: "020002")
    option_de_rang_1 = Fabricate(:option_pedagogique, code_matiere_6: "010001")
    Fabricate(:mef_option_pedagogique, mef: mef, option_pedagogique: option_facultative, rang_option: nil)
    Fabricate(:mef_option_pedagogique, mef: mef, option_pedagogique: option_de_rang_2, rang_option: 2)
    Fabricate(:mef_option_pedagogique, mef: mef, option_pedagogique: option_de_rang_1, rang_option: 1)
    dossier = Fabricate(:dossier_eleve,
                        etablissement: admin.etablissement,
                        mef_destination: mef,
                        options_pedagogiques: [option_facultative, option_de_rang_2, option_de_rang_1])

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    options = xml.xpath("//SCOLARITE_ACTIVE/OPTIONS/OPTION")
    assert_equal option_de_rang_1.code_matiere_6, options[0].xpath("CODE_MATIERE").text
    assert_equal option_de_rang_2.code_matiere_6, options[1].xpath("CODE_MATIERE").text
    assert_equal option_facultative.code_matiere_6, options[2].xpath("CODE_MATIERE").text
  end

  test "retourne l'information à propos du paiement des frais de scolarité" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    resp_qui_paie = Fabricate(:resp_legal, paie_frais_scolaires: true)
    resp_qui_paie_pas = Fabricate(:resp_legal, paie_frais_scolaires: false)
    dossier = Fabricate(:dossier_eleve, etablissement: admin.etablissement, resp_legal: [resp_qui_paie, resp_qui_paie_pas])

    get export_siecle_configuration_exports_path(xml_only: true), params: { limite: true, liste_ine: dossier.eleve.identifiant }

    assert_response :success

    schema = Rails.root.join("doc/import_prive/schema_Import_3.1.xsd")
    Nokogiri::XML::Schema(File.read(schema))
    xml = Nokogiri::XML(response.body)

    responsables = xml.xpath("//ELEVES/ELEVE/RESPONSABLES_ELEVE/LEGAL")
    assert_equal 2, responsables.length
    responsables.each do |noeud_legal|
      id_prv_resp = noeud_legal.xpath("ID_PRV_PER").text
      paie_frais_scolaires = noeud_legal.xpath("PAIE_FRAIS_SCOLAIRES").text
      if id_prv_resp == resp_qui_paie.id.to_s
        assert_equal "1", paie_frais_scolaires
      else
        assert_equal "0", paie_frais_scolaires
      end
    end
  end

end
