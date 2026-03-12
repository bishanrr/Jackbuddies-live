require "test_helper"

class PasswordResetFlowTest < ActionDispatch::IntegrationTest
  test "user can reset password with the secret code" do
    user = users(:approved_user)

    post verify_password_reset_path, params: { secret_code: "nhy6bgt5" }
    assert_redirected_to edit_password_reset_path

    patch password_reset_path, params: {
      email: user.email,
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    assert_redirected_to new_user_session_path

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "NewPassword123!"
      }
    }

    assert_redirected_to home_path
  end

  test "wrong secret code does not unlock password reset" do
    post verify_password_reset_path, params: { secret_code: "wrong-code" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid secret code."
  end
end
