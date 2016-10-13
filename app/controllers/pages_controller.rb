class PagesController < ApplicationController
  before_action :set_room, if: :user_signed_in?

  def index
    if user_signed_in?
      if @room.present?
        redirect_to @room
      else
        render "dashboard", layout: "application"
      end
    else
      session["new_user_role"] = 'client'
      render "index"
    end
  end

  def network
    if user_signed_in?
      if @room.present?
        redirect_to @room
      else
        render "dashboard", layout: "application"
      end
    else
      session["new_user_role"] = 'freelancer'
      render "network"
    end
  end

  def search_skills
    @skills = Skill.where('skill iLIKE ?', "%#{params[:term]}%") if params[:term]
    respond_to do |format|
      format.json {
        render :json => @skills.map(&:to_select2)
      }
    end
  end

  protected

  def set_room
    @room = current_user.asigned_rooms.first
  end
end
