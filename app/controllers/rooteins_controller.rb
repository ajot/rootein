class RooteinsController < ApplicationController
  before_action :set_rootein, only: [:show, :edit, :update, :destroy]

  def index
    @rooteins = Current.user.rooteins
  end

  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @completions = @rootein.completions
      .where(completed_on: @date.beginning_of_month..@date.end_of_month)
      .pluck(:completed_on)
      .to_set
  end

  def new
    @rootein = Current.user.rooteins.new
  end

  def create
    @rootein = Current.user.rooteins.new(rootein_params)
    if @rootein.save
      redirect_to @rootein, notice: "Rootein created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @rootein.update(rootein_params)
      redirect_to @rootein, notice: "Rootein updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rootein.destroy
    redirect_to rooteins_path, notice: "Rootein deleted."
  end

  private

  def set_rootein
    @rootein = Current.user.rooteins.find(params[:id])
  end

  def rootein_params
    params.expect(rootein: [:name, :active, :reminder_time, :remind_on_slack])
  end
end
