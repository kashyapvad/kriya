class PaymentsController < ApplicationController
  before_action :set_payment, only: [:show, :edit, :update, :destroy]

  # GET /payments
  # GET /payments.json
  def index
    @payments = Payment.all
  end

  # GET /payments/1
  # GET /payments/1.json
  def show
  end

  # GET /payments/new
  def new
    @payment = Payment.new
  end

  # GET /payments/1/edit
  def edit
  end

  # POST /payments
  # POST /payments.json
  def create
    amount = params[:amount]
    user = User.find payment_params[:user_id]
    msg = Message.find params[:message_id]
    room = msg.room
    update_customer = params[:update_customer].to_i

    # If user.stripe_id is nil, then this is the first payment for this user
    if user.stripe_id.nil? then
      token = params[:token][:id]
      customer = Stripe::Customer.create(
          :description => "Customer for user " + user.to_s,
          :source => token
      )

      # TODO: check for errors on API side here
      user.stripe_id = customer.id
      user.save
    end

    if update_customer == 1 then
      token = params[:token][:id]
      cu = Stripe::Customer.retrieve(user.stripe_id)
      cu.source = token
      cu.save
      msg.attachment.select_change_card_button
    else
      msg.attachment.select_pay_button
    end

    # Create a charge: this will charge the user's card
    begin
      charge = Stripe::Charge.create(
        :amount => amount, # Amount in cents
        :currency => "usd",
        :customer => user.stripe_id,
        :description => "Example charge"
      )
      room.messages.new({:body => 'The transaction was successful.', :room => room, :user => room.manager})
      room.save
      ActionCable.server.broadcast(
        "rooms:#{room.id}:messages",
        message: MessagesController.render(
          partial: 'messages/message',
          locals: {
            message: room.messages.last, user: room.manager
          }
        ),
        room_id: room.id,
      )
    # Catches at least CardError and InvalidRequestError
    rescue #Stripe::CardError => e
      # The card has been declined
      room.messages.new({:body => 'The transaction was unsuccessful. Please try again', :room => room, :user => room.manager})
      room.save
      ActionCable.server.broadcast(
        "rooms:#{room.id}:messages",
        message: MessagesController.render(
          partial: 'messages/message',
          locals: {
            message: room.messages.last, user: room.manager
          }
        ),
        room_id: room.id,
      )
      room.messages.new({:body => '/charge $' + (amount.to_i / 100).to_s, :room => room, :user => room.manager})
      room.messages.last.process_command
      room.save
      return
    end

    @payment = Payment.new(payment_params)

    respond_to do |format|
      if @payment.save
        format.html { redirect_to @payment, notice: 'Payment was successfully created.' }
        format.json { head :no_content }
      else
        format.html { render :new }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /payments/1
  # PATCH/PUT /payments/1.json
  def update
    respond_to do |format|
      if @payment.update(payment_params)
        format.html { redirect_to @payment, notice: 'Payment was successfully updated.' }
        format.json { render :show, status: :ok, location: @payment }
      else
        format.html { render :edit }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /payments/1
  # DELETE /payments/1.json
  def destroy
    @payment.destroy
    respond_to do |format|
      format.html { redirect_to payments_url, notice: 'Payment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment
      @payment = Payment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def payment_params
      params.require(:payment).permit(:user_id)
    end
end
