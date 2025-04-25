module Api
  class UsersController < ApplicationController
    def index
      render json: { users: User.all }
    end

    def create
      @user = User.new(user_params)

      if @user.save
        render json: { user: @user }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :role)
    end
  end
end
