class DashboardController < ApplicationController
  def show
    rooteins = Current.user.rooteins.active
    @slacking = rooteins.slacking
    @on_target = rooteins.on_target
    @tip = Tip.order("RANDOM()").first
    @greeting = random_greeting
  end

  private

  def random_greeting
    greetings = [
      "Hello", "Hola", "Bonjour", "Hej", "Ciao",
      "Namaste", "Konnichiwa", "Olá", "Salaam", "Aloha"
    ]
    "#{greetings.sample}, #{Current.user.email_address.split('@').first}!"
  end
end
