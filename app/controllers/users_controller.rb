class UsersController < ApplicationController
  before_action :require_correct_user, only: [:edit, :update, :delete, :destroy]
  before_action :must_be_beta_approved, only: [:show]

  def new
    @user = User.new
    respond_to do |format|
      format.html { }
      format.js { render :new }
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      cookies.signed[:user_id] = { value: @user.id, expires: 6.months.from_now }
      redirect_to decks_path,
      notice: "Thanks for signing up!"
    else
      render :new
    end
  end

  def show
    @user = User.where(id: params[:id]).includes(:decks, :cards).first
  end

  def edit
    @user = user
  end

  def update
    @user = user

    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Account updated.' }
        format.json { render json: @user }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: @user, status: :unprocessable_entity }
      end
    end
  end

  def delete
    @user = user
  end

  def update_password
    @user = user

    if password_is_wrong?
      @user.errors[:current_password] = 'is incorrect.'
    end

    if @user.update_password(password_params)
      redirect_to edit_user_path(@user), notice: "Password updated successfuly."
    else
      render :edit_password
    end
  end

  def destroy
    @user.destroy
    destroy_session
    redirect_to root_url, notice: 'Account deleted successfuly.'
  end

  def edit_password
    @user = user
  end

private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :website,
      :email, :password, :password_confirmation, :user_saw_welcome_message)
  end

  def password_params
    params.require(:user).permit(:password, :new_password, :new_password_confirmation)
  end

  def filled_in_a_password?
    return false if password_params[:password].nil?
  end

  def require_correct_user
    redirect_to root_url unless current_user && (user == current_user)
  end

  def user
    @user ||= User.find(params[:id])
  end

  def password_is_wrong?
    return true if User.authenticate(@user.email, password_params[:password]) == false
  end
end
