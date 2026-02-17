module RooteinsHelper
  def streak_color(rootein)
    streak = rootein.current_streak
    if streak >= 21
      "bg-yellow-500 border-yellow-600"
    elsif streak > 0
      "bg-green-500 border-green-600"
    else
      "bg-red-500 border-red-600"
    end
  end

  def streak_badge(rootein)
    streak = rootein.current_streak
    content_tag(:span, class: "inline-flex flex-col items-center justify-center w-12 h-12 rounded-lg border #{streak_color(rootein)} text-white font-bold leading-tight shadow-sm") do
      content_tag(:span, streak, class: "text-lg") +
      content_tag(:span, "days", class: "text-[10px] -mt-0.5")
    end
  end
end
