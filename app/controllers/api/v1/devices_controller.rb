class Api::V1::DevicesController < ApplicationController
  skip_before_action :verify_authenticity_token

  # control a device
  def control
    # get the device
    device = Device.find_by(id: params[:id])

    # error if invalid
    render json: { error: 'Invalid device credentials.' } and return if device.blank?

    # check the authentication
    valid = true if Devise.secure_compare(device.auth_token, params[:auth_token])

    # error if invalid
    render json: { error: 'Invalid device credentials.' } and return if valid != true

    # create the base message
    message = { "pin" => params[:pin] }

    # add a servo message
    message.merge!({ "servo" => params[:servo].to_i }) if params[:servo].present?

    # add a digital on/off message
    message.merge!({ "digital" => params[:digital] }) if params[:digital].present?

    # broadcast the command to the device
    device.broadcast_message(message)

    # blank http 200 response
    head :ok
  end

  # create a new device
  def create
    # create the anonymous device
    device = Device.create
    # output the auth_token
    render plain: device.to_json
  end

  # create the dynamic nodejs script
  def nodejs_script
    # get the device
    @device = Device.find_by(id: params[:id])

    # error if invalid
    render plain: { error: 'Invalid device credentials.' } and return if @device.blank?

    # check the authentication
    valid = true if Devise.secure_compare(@device.auth_token, params[:auth_token])

    # error if invalid
    render plain: { error: 'Invalid device credentials.' } and return if valid != true

    # set the websocket server url
    @websocket_server_url = Rails.env.production? ? 'wss://limitos.com/cable' : "ws://#{request.host}:#{request.port}/cable"

    # don't use a layout
    render partial: 'shared/nodejs_script', layout: false, content_type: 'text/plain'
  end

end
