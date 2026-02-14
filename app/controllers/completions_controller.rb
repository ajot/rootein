class CompletionsController < ApplicationController
  before_action :set_rootein
  
  def create
    @rootein.completions.create!(completed_on: params[:completed_on])
    redirect_to rootein_path(@rootein, date: params[:completed_on])
  end

  def destroy
    @rootein.completions.find(params[:id]).destroy
    redirect_to rootein_path(@rootein, date: params[:completed_on])
  end

  private

  def set_rootein
    @rootein = Rootein.find(params[:rootein_id])
  end
end