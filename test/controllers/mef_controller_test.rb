# frozen_string_literal: true

require "test_helper"

class MefControllerTest < ActionDispatch::IntegrationTest

  setup do
    @mef = Fabricate(:mef)
  end

  test "should get index" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    get configuration_mef_index_url
    assert_response :success
  end

  test "should get new" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    get new_configuration_mef_url
    assert_response :success
  end

  test "should create mef" do
    admin = Fabricate(:admin)
    etablissement = Fabricate(:etablissement)
    identification_agent(admin)

    params = { mef: { code: rand(1000), libelle: rand(1000), etablissement: etablissement } }
    assert_difference("Mef.count") do
      post configuration_mef_index_url, params: params
    end

    assert_redirected_to configuration_mef_index_url
  end

  test "should get edit" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    get edit_configuration_mef_url(@mef)
    assert_response :success
  end

  test "should update mef" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    patch configuration_mef_url(@mef), params: { mef: { code: @mef.code, libelle: @mef.libelle } }
    assert_redirected_to configuration_mef_index_url
  end

  test "should destroy mef" do
    admin = Fabricate(:admin)
    identification_agent(admin)

    assert_difference("Mef.count", -1) do
      delete configuration_mef_url(@mef)
    end

    assert_redirected_to configuration_mef_index_url
  end

end
