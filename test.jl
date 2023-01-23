using Stipple, StippleUI, Stipple.ReactiveTools

@reactive mutable struct Name <: ReactiveModel
  name::R{String} = "World!"
end

function ui(model)
  page( model, class="container", [
      h1([
        "Hello "
        span("", @text(:name))
      ])

      p([
        "What is your name? "
        input("", placeholder="Type your name", @bind(:name))
      ])
    ]
  )
end

@page

route("/") do
  model = Name |> init
  html(ui(model), context = @__MODULE__)
end


task = up(async=false) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app
