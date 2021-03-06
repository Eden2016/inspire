class SubscribersController < ApplicationController
  before_action :load_subscriber
  skip_before_action :load_subscriber, only: %i(new create index)
  before_action :load_user, only: %i(new create index)

  def index
    session[:root_page] = subscribers_path
    @subscribers = @user.subscribers

    respond_to do |format|
      format.html
      format.json { render json: @subscribers }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @subscriber }
    end
  end

  def new
    @subscriber = @user.subscribers.new
    respond_to do |format|
      format.html
      format.json { render json: @subscriber }
    end
  end

  def edit; end

  def create
    @subscriber = @user.subscribers.new(subscriber_params)
    respond_to do |format|
      if @subscriber.save
        format.html { redirect_to @subscriber, notice: "Subscriber was successfully created." }
        format.json { render json: @subscriber, status: :created, location: @subscriber }
      else
        format.html { render action: :new }
        format.json { render json: @subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @subscriber.update(subscriber_params)
        format.html { redirect_to @subscriber, notice: "Subscriber was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: :edit }
        format.json { render json: @subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @subscriber.destroy
    respond_to do |format|
      format.html { redirect_to subscribers_path }
      format.json { head :no_content }
    end
  end

  private

    def subscriber_params
      params.require(:subscriber)
        .permit(:name, :phone_number, :remarks, :email, :additional_attributes)
    end

    def load_user
      authenticate_user!
      @user = current_user
    end

    def load_subscriber
      authenticate_user!
      @user = current_user
      @subscriber = @user.subscribers.find(params[:id])
      redirect_to root_url, alert: "Access Denied" unless @subscriber
    rescue ActiveRecord::RecordNotFound
      redirect_to root_url, alert: "Access Denied"
    end
end
