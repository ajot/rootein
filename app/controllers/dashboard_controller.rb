class DashboardController < ApplicationController
  def show
    rooteins = Current.user.rooteins.active
    @slacking = rooteins.slacking
    @on_target = rooteins.on_target
    @tip = Tip.order("RANDOM()").first
    @greeting_word, @greeting_language = random_greeting
    @name = Current.user.name.presence || Current.user.email_address.split("@").first
  end

  private

  def random_greeting
    greetings = {
      "Welcome" => "English", "Bienvenido" => "Spanish", "Bienvenue" => "French",
      "Välkommen" => "Swedish", "Benvenuto" => "Italian", "Namaste" => "Hindi",
      "Youkoso" => "Japanese", "Bem-vindo" => "Portuguese", "Salaam" => "Arabic",
      "Aloha" => "Hawaiian"
    }
    greetings.to_a.sample
  end
end
