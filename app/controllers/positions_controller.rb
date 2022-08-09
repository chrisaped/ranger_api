class PositionsController < ApplicationController
  def create
    render json: { status: 'position created'}
  end
end
