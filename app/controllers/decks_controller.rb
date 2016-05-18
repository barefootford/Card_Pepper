class DecksController < ApplicationController
  before_action :require_sign_in, except: [:show, :index]
  before_action :require_creator, only: [:edit, :update, :destroy]
  before_action :deck, only: [:show, :edit, :update, :destroy, :download]
  before_action :dont_show_edit_button, only: [:show]
  before_action :do_show_edit_button, only: [:edit]
  before_action :must_be_beta_approved

  def anki_import
    respond_to do |format|
      format.js { render :anki_import }
    end
  end

  def index
    @decks = Deck.all.limit(10)
  end

  def show
    @card_suggestion = CardSuggestion.new
    @cards = deck.cards
    set_deck_subscription if current_user.present?

    respond_to do |format|
      format.html
      format.csv { download_csv }
    end
  end

  def edit
    @card_suggestions = @deck.card_suggestions.pending
    @new_card = @deck.cards.build
    @cards = @deck.cards.saved.includes(:user)
    @new_style_cards = @cards.collect do |card|
      card = Card.addClientSideAttributes(card)
    end
  end

  def update
    @deck.update(deck_params)
    redirect_to edit_deck_path(@deck), notice: "Deck updated successfully."
  end

  def destroy
    @deck.destroy
    redirect_to root_url, notice: 'Deck deleted successfully.'
  end

  def new
    @new_deck = current_user.decks.build
  end

  def create
    @new_deck = current_user.decks.new(deck_params)
    if @new_deck.save
       redirect_to edit_deck_path(@new_deck), notice: "Deck built successfully."
    else
      render :new
    end
  end

private
  def set_deck_subscription
    if current_user.deck_subscriptions.where(deck: deck).any?
      @deck_subscription = current_user.deck_subscriptions.where(deck: deck).first
    else
      @new_deck_subscription = current_user.deck_subscriptions.new(deck: deck) 
    end
  end

  def download_csv
    send_data @deck.to_csv, filename: @deck.file_name
  end

  def dont_show_edit_button
    @show_edit_button = false
  end

  def do_show_edit_button
    @show_edit_button = true
  end

  def require_creator
    unless current_user && current_user == deck.user
      redirect_to root_url, notice: "Only the deck's creator can edit the deck."
    end
  end

  def set_deck
    deck
  end

  def deck
    @deck ||= Deck.find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:title,:editor,:instructions)
  end
end