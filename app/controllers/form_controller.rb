class FormController < ApplicationController
  include Phantom

  def index
    @site = Phantom::Site.new(params[:name])
    @fields = @site.fields
  end

  def go
    @site = Phantom::Site.new(params[:name])
    @site.match_fields(params)
    render :text => @site.phantom!
  end

  def info
    @site = Phantom::Site.new(params[:name])
    render :text => @site.inspect
  end
  
end
