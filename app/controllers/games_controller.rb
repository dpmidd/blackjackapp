class GamesController < ApplicationController

  def index
  end

  def show
    @user = current_user
    @hand = Hand.new(user_id: @user.id)
    @game = Game.find(params[:id])
    @cards = Card.where(game_id: @game.id)
    @player_cards = @cards.select{|card| card.player == 'you' }
    @dealer_cards = @cards.select{|card| card.player == 'dealer' }
    @player_cards_value = Card.get_value_of_cards(@player_cards)
    @dealer_cards_value = Card.get_value_of_cards(@dealer_cards)
  end

  def create
    game = Game.new({:created_at => Time.now})
    game.save
    redirect_to game_path(game)
  end

  def update

    if params[:commit] == "Deal Cards"
      GameGenerator.generate_cards(params[:id])
      @game = Game.find(params[:id])
      @cards = @game.cards
      Card.get_four_random_cards(@cards, session[:user_id])
    end

    @game = Game.find(params[:id])
    @cards = Card.where(game_id: @game.id)

    if params[:commit] == "Hit"
      Card.give_player_a_card(@cards)
    end

    @dealer_cards = @cards.select{|card| card.player == 'dealer' }
    @dealer_cards_value = Card.get_value_of_cards(@dealer_cards)
    @player_cards = @cards.select{|card| card.player == 'you' }
    @player_cards_value = Card.get_value_of_cards(@player_cards)

    if @player_cards_value > 21
      @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      @game.winner = 'dealer'
      @game.save
    end

    if params[:commit] == "Stand"
      @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      @dealer_cards_value = Card.get_value_of_cards(@dealer_cards)
      if @dealer_cards_value > @player_cards_value
        @game.winner = 'dealer'
        @game.save
      else
        Card.run_dealers_hand(@game, @cards, @dealer_cards_value, @player_cards_value)
      end
    end

    if params[:commit] == "Double Down"
      Card.give_player_a_card(@cards)
      @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      @dealer_cards_value = Card.get_value_of_cards(@dealer_cards)
      @player_cards_value = Card.get_value_of_cards(@player_cards)

      if @player_cards_value > 21
        @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
        @game.winner = 'dealer'
        @game.save
      end

      #Player can't click anything else the hand for the player is finished
      if @dealer_cards_value > @player_cards_value
        @game.winner = 'dealer'
        @game.save
      else
        Card.run_dealers_hand(@game, @cards, @dealer_cards_value, @player_cards_value)
      end
    end

    if @player_cards_value == 21
      @game.winner = current_user.id
      @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)

      #This logic wouldn't work we need to check for 21 for the dealer and the user
      #isnt the default winner if it's after the first two cards so its only on when the first
      #two cards in the array equate to 21

      if @dealer_cards_value == 21
        @game.winner = 'push'
      end

      @game.save
    end


    if @player_cards_value > 21
      @game.winner = 'dealer'
      @game.save
      @cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
    end

    if @dealer_cards_value > 21
      @game.winner = current_user.id
      @game.save
    end

    if @dealer_cards_value > @player_cards_value && @dealer_cards_value <= 21
      @game.winner = 'dealer'
      @game.save
    end

    redirect_to game_path(@game)
  end
end
