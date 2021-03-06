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

    freelancers = room.in_progress_freelancers + room.completed_freelancers
    freelancer = freelancers.first

    # If user.stripe_id is nil, then this is the first payment for this user
    if user.stripe_id.nil?
      token = params[:token][:id]
      customer = Stripe::Customer.create(
          :description => "Customer for user " + user.to_s,
          :source => token
      )

      # TODO: check for errors on API side here
      user.stripe_id = customer.id
      user.save
    end

    if update_customer == 1
      token = params[:token][:id]
      cu = Stripe::Customer.retrieve(user.stripe_id)
      cu.source = token
      cu.save
      msg.attachment.select_change_card_button
    else
      msg.attachment.select_pay_button
    end

    begin
      charge = Stripe::Charge.create(
        :amount => amount, # Amount in cents
        :currency => "usd",
        :customer => user.stripe_id,
        :description => "Kriya Task - #{room.title}"
      )

      message = room.messages.create(body: 'The transaction was successful.', room: room, user: room.manager, msg_type: 'bot-charge-success')

      if amount.to_i == room.escrow_amount_cents.to_i && room.first_paid_amount_cents == 0
        room.update(first_paid_amount_cents: amount.to_i)
        Payment::FirstEscrowWorker.perform_async(room.id, amount.to_i)

      # Rating after task complete
      elsif (room.first_paid_amount_cents + amount.to_i) == room.budget_cents_including_fee
        message.assign_attributes({:body => 'The transaction was successful. What is the rate of this work?', :room => room, :user => room.manager, :msg_type => 'bot-ask-rate'})
        freelancer_rooms = room.freelancers_rooms.where('status in (?)', ['accepted', 'more_work', 'not_finished']).where("freelancer_id = ?", freelancer.id)

        if freelancer_rooms.any?
          freelancer_room_id = freelancer_rooms[0].id
        else
          freelancer_room_id = ''
        end

        message.create_attachment html: "<br/>"

        (1..5).each do |i|
          message.attachment.html += <<~HTML.squish
            <button id="customRateButton#{i}-#{message.id}" class="mini ui green button custom-padding">#{i}</button>
            <script>
              document.getElementById("customRateButton#{i}-#{message.id}").addEventListener('click', function(e) {
                $.post("/freelancer_rates.json", {
                    freelancer_rate: {
                      rate: #{i},
                      user_id: #{room.user.id},
                      room_id: #{room.id},
                      freelancer_id: #{freelancer.id},
                      freelancers_room_id: #{freelancer_room_id}
                    }
                  });
                e.preventDefault();

              });
            </script>
          HTML
        end
        message.save
        message.attachment.save
      end
    # Catches at least CardError and InvalidRequestError
    rescue Exception => e#Stripe::CardError => e
      # The card has been declined
      puts e.message
      room.messages.new({:body => 'The transaction was unsuccessful. Please try again', :room => room, :user => room.manager, :msg_type => 'bot-failed-payment'})
      room.save
      room.messages.new({:body => '/charge $' + (amount.to_i / 100).to_s, :room => room, :user => room.manager})
      room.messages.last.process_command
      room.save
      return
    end

    @payment = Payment.new(payment_params)

    if @payment.save
      redirect_to room_path(room)
    else
      render :new
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
      params.require(:payment).permit(:user_id, :freelancer_id)
    end
end
