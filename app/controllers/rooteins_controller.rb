class RooteinsController < ApplicationController
  def index
    @rooteins = Rootein.all
  end

  def show
    @rootein = Rootein.find(params[:id])
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
    @completions = @rootein.completions.where(completed_on: @date.beginning_of_month..@date.end_of_month).pluck(:completed_on).to_set
  end
end
