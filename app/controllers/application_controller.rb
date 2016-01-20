class ApplicationController < ActionController::Base
  protect_from_forgery

  include Phantom
  helper Phantom::FieldHelper
  
end
