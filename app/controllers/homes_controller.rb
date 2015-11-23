class HomesController < ApplicationController
  def index
    @homes = Home.order(id: :desc)
  end
  
  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @home = Home.find(params[:id])
    respond_to do |format|
      if @home.update(home_params)
        format.html { 
          redirect_to @home, notice: 'Home was successfully updated.' 
        }
        format.json {
          puts "render json"
          render json: {id: @home.id, value: @home.value.to_s, score: @home.scorecard.calculate_score.to_s}
        }
        format.js {   
          puts "render js"
          head :no_content 
        }
      else
        format.html { render :edit }
        format.json { render json: @home.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @home = Home.where(listing_id: params[:id]).first
  end

  def home_params
    params.require(:home).permit(:notes, :ranking, scorecard_attributes: [:id, :kitchen, :yard, :layout, :location, :light, :charm, :potential])
  end

  def ranked
    @homes = Home.where('ranking > 5').order(ranking: :desc)
    render :index
  end
  
  def unreviewed
    @homes = Home.where('ranking is null')
    render :index
  end
end