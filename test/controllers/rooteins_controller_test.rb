require "test_helper"

class RooteinsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get rooteins_index_url
    assert_response :success
  end
end
