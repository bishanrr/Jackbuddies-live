module ApplicationHelper
  def nav_link_class(path)
    base = "flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition"
    active = current_page?(path) ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
    "#{base} #{active}"
  end

  def stage_badge_class(stage)
    case stage.to_s
    when "league" then "bg-sky-100 text-sky-700"
    when "qualifier" then "bg-amber-100 text-amber-700"
    when "eliminator" then "bg-orange-100 text-orange-700"
    else "bg-rose-100 text-rose-700"
    end
  end

  def status_badge_class(status)
    status.to_s == "completed" ? "bg-emerald-100 text-emerald-700" : "bg-slate-100 text-slate-700"
  end
end
