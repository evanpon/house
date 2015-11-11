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
          puts "html?"
          redirect_to @home, notice: 'Home was successfully updated.' }
        format.js { 
          puts "json!"
          head :no_content }
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
    params.require(:home).permit(:notes, :ranking)
  end

  def ranked
    @homes = Home.where('ranking > 0').order(ranking: :desc)
    render :index
  end
  
  def unreviewed
    @homes = Home.where('ranking is null')
    render :index
  end
end