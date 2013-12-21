class RanksController < ApplicationController

  def create
    @rank = Rank.new(rank_params)
    if @rank.save
      redirect_to @rank
    else
      render "new"
    end
  end

  protected

  def rank_params
    params.require(:rank).permit(:name)
  end

end