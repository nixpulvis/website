# UsersController
# Controller for the User model.
#
# Actions: [index, new, create, show, edit, update, toggle, destroy]
#
class UsersController < ApplicationController
  before_action only: [:show, :edit, :update, :toggle, :destroy] do
    @user = User.find(params[:id])
    authorize @user
  end

  # GET /users
  # As admin, provides all the users.
  # As non-admin, redirects with access error.
  #
  def index
    @users = policy_scope(User)
             .includes(:avatar, :main, :rank)
             .order(created_at: :desc)
             .page(params[:page])

    @users = @users.where(hidden: false) unless params[:hidden]

    authorize @users
  end

  # GET /users/new
  # Builds a User and a Character for the user to create an account.
  #
  def new
    @user = User.new
    @main = @user.characters.build
    authorize @user
  end

  # POST /users
  # Creates a new User with the passed in parameters, this includes nested
  # character parameters. Redisplays the new page when there are errors.
  #
  def create
    @user = User.new(user_params)
    @main = @user.main
    authorize @user

    if @user.save
      sign_in(@user)
      redirect_to(@user)
    else
      render :new
    end
  end

  # GET /users/:id
  # Provides the user, and it's posts.
  #
  # FIXME: This is incredibly inefficient. Please god fix me.
  #
  def show
    posts = policy_scope(@user.posts)
    postables = posts.map(&:postable).uniq

    @postables = postables.map do |p|
      [p, p.posts.where(user: @user).last, p.posts.where(user: @user).count]
    end
    @postables.sort! do |a, b|
      b[1].created_at <=> a[1].created_at
    end

    @postables = Kaminari.paginate_array(@postables)
                 .page(params[:page])
                 .per(15)
  end

  # GET /users/:id/edit
  # Provides the user.
  #
  def edit
  end

  # PATCH or PUT /users/:id
  # Allows for users to update their attributes.
  #
  # rubocop:disable Metrics/AbcSize
  def update
    # Assume user is not trying to update password if the password is blank.
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # Append an error for the admin field if you are trying to make yourself
    # not an admin.
    if params[:user][:admin] == '0' &&
       current_user.admin? &&
       current_user == @user
      @user.errors.add(:admin?, "can't be disabled by the same user")
      render :edit
      return
    end

    # Don't make an Upload unless we are given a file.
    unless params[:user][:avatar_attributes][:file]
      params[:user][:avatar_attributes] = nil
    end

    if @user.update_attributes(user_params)
      sign_in @user, bypass: true if @user == current_user
      redirect_to @user
    else
      render :edit
    end
  end

  # PATCH /users/:id/toggle
  # Hide or show the given user, setting it's hidden attribute.
  #
  def toggle
    @user.toggle
    redirect_to :back
  end

  # DELETE /users/:id
  # Destroy the user, and everything it did.
  #
  def destroy
    @user.destroy
    sign_out if @user == current_user
    redirect_to root_path, notice: "#{@user.email} deleted"
  end

  private

  # user_params: -> Hash
  # Permits the user fields for assignment.
  #
  def user_params
    params.require(:user).permit(*policy(@user || User).permitted_attributes)
  end
end
