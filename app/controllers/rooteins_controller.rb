class RooteinsController < ApplicationController
  def index
    @rooteins = Rootein.all
  end
end
