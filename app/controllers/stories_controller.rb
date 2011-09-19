class StoriesController < ApplicationController

  include ActionView::Helpers::TextHelper

  def index
    @project = current_user.projects.find(params[:project_id])
    @stories = @project.stories
    render :json => @stories
  end

  def show
    @project = current_user.projects.find(params[:project_id])
    @story = @project.stories.find(params[:id])
    render :json => @story
  end

  def update
    @project = current_user.projects.find(params[:project_id])
    @story = @project.stories.find(params[:id])
    @story.acting_user = current_user
    respond_to do |format|
      if @story.update_attributes(filter_story_params)
        format.html { redirect_to project_url(@project) }
        format.js   { render :json => @story }
      else
        format.html { render :action => 'edit' }
        format.js   { render :json => @story, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @project = current_user.projects.find(params[:project_id])
    @story = @project.stories.find(params[:id])
    @story.destroy
    head :ok
  end

  def done
    @project = current_user.projects.find(params[:project_id])
    @stories = @project.stories.done
    render :json => @stories
  end
  def backlog
    @project = current_user.projects.find(params[:project_id])
    @stories = @project.stories.backlog
    render :json => @stories
  end
  def in_progress
    @project = current_user.projects.find(params[:project_id])
    @stories = @project.stories.in_progress
    render :json => @stories
  end

  def create
    @project = current_user.projects.find(params[:project_id])
    @story = @project.stories.build(filter_story_params)
    @story.requested_by_id = current_user.id unless @story.requested_by_id
    respond_to do |format|
      if @story.save
        @task = @story.tasks.build(:description => params[:tasks])
        @comment = @story.comments.build(:description => params[:comments])
        @task.save && @comment.save
        format.html { redirect_to project_url(@project) }
        format.js   { render :json => @story }
      else
        format.html { render :action => 'new' }
        format.js   { render :json => @story, :status => :unprocessable_entity }
      end
    end
  end

  def start
    state_change(:start!)
  end

  def finish
    state_change(:finish!)
  end

  def deliver
    state_change(:deliver!)
  end

  def accept
    state_change(:accept!)
  end

  def reject
    state_change(:reject!)
  end

  # CSV import form
  def import
    @project = current_user.projects.find(params[:project_id])
  end

  # CSV import
  def import_upload

    @project = current_user.projects.find(params[:project_id])

    stories = []

    if params[:csv].blank?

      flash[:alert] = "You must select a file for import"

    else

      # FIXME Move to model
      begin

        # Eager load this so that we don't have to make multiple db calls when
        # searching for users by full name from the CSV.
        users = @project.users

        csv = CSV.parse(File.read(params[:csv].path), :headers => true)
        csv.each do |row|
          row = row.to_hash
          stories << {
            :state => row["Current State"],
            :title => row["Story"],
            :story_type => row["Story Type"],
            :requested_by => users.detect {|u| u.name.downcase == row["Requested By"].downcase},
            :owned_by => users.detect {|u| u.name.downcase == row["Owned By"].downcase},
            :accepted_at => row["Accepted at"],
            :estimate => row["Estimate"],
            :description => row["Description"]
          }
        end
        @stories = @project.stories.create(stories)
        @valid_stories = @stories.select(&:valid?)
        @invalid_stories = @stories.reject(&:valid?)
        flash[:notice] = "Imported #{pluralize(@valid_stories.count, "story")}"

        unless @invalid_stories.empty?
          flash[:alert] = "#{pluralize(@invalid_stories.count, "story")} failed to import"
        end
      rescue CSV::MalformedCSVError => e
        flash[:alert] = "Unable to import CSV: #{e.message}"
      end

    end

    render 'import'

  end

  # Export Project stories as CSV
  def export
    @project = current_user.projects.find(params[:project_id])
    stories = CSV.generate do |csv|
      csv << ['Id','Story','Labels','Iteration','Iteration Start','Iteration End','Story Type','Estimate','Current State','Created at','Accepted at','Deadline','Requested By','Owned By','Description','URL','Note']
      @project.stories.each do |story|
        requested_by = User.find(story.requested_by_id).present? ? User.find(story.requested_by_id).name: '-'
        owned_by = User.find(story.owned_by_id).present? ? User.find(story.owned_by_id).name : '-'
        csv << [story.id, story.title, '', '', '', '', story.story_type, story.estimate, story.state, story.created_at, story.accepted_at, '', requested_by, owned_by, story.description, '', '']
      end
    end

    send_data(stories, :type => 'text/csv', :filename => "export.csv")
  end
  
  private
  def state_change(transition)
    @project = current_user.projects.find(params[:project_id])

    @story = @project.stories.find(params[:id])
    @story.send(transition)

    redirect_to project_url(@project)
  end

  # Removes all unwanted keys from the params hash passed for Backbone
  def filter_story_params
    allowed = [
      :title, :description, :estimate, :story_type, :state, :requested_by_id,
      :owned_by_id, :position
    ]
    filtered = {}
    params[:story].each do |key, value|
      filtered[key.to_sym] = value if allowed.include?(key.to_sym)
    end
    filtered
  end
end
