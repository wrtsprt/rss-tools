require 'test_helper'

class EnhancersControllerTest < ActionController::TestCase
  setup do
    @enhancer = enhancers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:enhancers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create enhancer" do
    assert_difference('Enhancer.count') do
      post :create, enhancer: @enhancer.attributes
    end

    assert_redirected_to enhancer_path(assigns(:enhancer))
  end

  test "should show enhancer" do
    get :show, id: @enhancer
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @enhancer
    assert_response :success
  end

  test "should update enhancer" do
    put :update, id: @enhancer, enhancer: @enhancer.attributes
    assert_redirected_to enhancer_path(assigns(:enhancer))
  end

  test "should destroy enhancer" do
    assert_difference('Enhancer.count', -1) do
      delete :destroy, id: @enhancer
    end

    assert_redirected_to enhancers_path
  end
end
