class HomesController < ApplicationController
  def index
    @homes = Home.all
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

  def home_params
    params.require(:home).permit(:notes, :ranking)
  end

  def ranked
    @homes = Home.order(ranking: :desc)
    render :index
  end
end