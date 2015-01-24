class Calculator

  def self.calculate(params, session)
    runner = new(params, session)
    runner.run
  end

  attr_reader :params, :session
  attr_accessor :game, :dealer_cards, :dealer_cards_value, :player_cards, :player_cards_value, :cards
  
  def initialize(params, session)
    @params = params
    @session = session
  end

  def run
    if params[:commit] == "Deal Cards"
      setup_new_game
    end

    self.game = Game.find(params[:id])
    self.cards = Card.where(game_id: game.id)

    def self.hit
      if params[:commit] == "Hit"
        self.Card.give_player_a_card(cards)
        self.cards = Card.where(game_id: game.id)
        self.player_cards = cards.select{|card| card.player == 'you'}
        self.player_cards_value = Card.get_value_of_cards(player_cards)
        self.dealer_cards = cards.select{|card| card.player == 'dealer'}
        self.dealer_cards_value = Card.get_value_of_cards(dealer_cards)
        if self.player_cards_value > 21
          self.game.winner = 'dealer'
          self.game.save
        end
      end
    end

    self.dealer_cards = cards.select{|card| card.player == 'dealer'}
    self.dealer_cards_value = Card.get_value_of_cards(dealer_cards)
    self.player_cards = cards.select{|card| card.player == 'you' }
    self.player_cards_value = Card.get_value_of_cards(player_cards)

    def self.stand
      if params[:commit] == "Stand"
        self.cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
        self.dealer_cards_value = self.Card.get_value_of_cards(dealer_cards)
        if self.dealer_cards_value > self.player_cards_value && self.player_cards_value < 21
          self.game.winner = 'dealer'
          self.game.save
        end
        if self.player_cards_value > self.dealer_cards_value && self.player_cards_value < 21
          self.Card.run_dealers_hand(self.game, self.cards, self.dealer_cards_value, self.player_cards_value)
        end
      end
    end

    def self.doubledown
      if params[:commit] == "Double Down"
        self.Card.give_player_a_card(cards)
        self.cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
        self.dealer_cards_value = self.Card.get_value_of_cards(dealer_cards)
        self.player_cards_value = self.Card.get_value_of_cards(player_cards)

        if self.player_cards_value <= 21 && self.dealer_cards_value < self.player_cards_value
          self.Card.run_dealers_hand(game, cards, dealer_cards_value, player_cards_value)
        end

        if player_cards_value > 21
          self.game.winner = 'dealer'
          self.game.save
        end
      end
    end

    # if player_cards_value > 21 && #Has an ace
    #   #ace value goes from 11 to 1
    # end

    if dealer_cards_value > player_cards_value && dealer_cards_value < 21
      self.game.winner = 'dealer'
      self.game.save
    end

    if dealer_cards_value == 21 && player_cards_value < 21
      cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      game.winner = 'dealer'
      game.save
    end

    if player_cards_value == 21
      cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      Card.run_dealers_hand(game, cards, dealer_cards_value, player_cards_value)
      if dealer_cards_value == 21 #and the player received 21 after the first two cards
        game.winner = 'push'
      else
        game.winner = 'you'
      end
      game.save
    end

    if player_cards_value > 21
      cards.select { |card| card.face_up == false }[0].try(:update, face_up: true)
      game.winner = 'dealer'
      game.save
    end

    if dealer_cards_value > 21 && player_cards_value <= 21
      game.winner = 'you'
      game.save
    end

    if dealer_cards_value <= 21 && player_cards_value < 21 && dealer_cards_value > player_cards_value
      game.winner = 'dealer'
      game.save
    end

    if dealer_cards_value == 21 && player_cards_value == 21
      game.winner = 'push'
      game.save
    end

    if dealer_cards_value == player_cards_value && dealer_cards_value < 21 && player_cards_value < 21
      game.winner = 'push'
      game.save
    end

    {
      game: game,
      dealer_cards_value: dealer_cards_value,
      player_cards_value: player_cards_value,
      cards: cards,
    }
  end

  def setup_new_game
    GameGenerator.generate_cards(params[:id])
    self.game = Game.find(params[:id])
    self.cards = game.cards
    Card.get_four_random_cards(cards, session[:user_id])
  end
end