class PositionsController < ApplicationController
  def process
    puts "here are the process params:"
    p params
    # handle the order response
    # render json: handled_order_response
  end
end
