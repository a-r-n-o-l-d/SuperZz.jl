module SuperZz
  using GenieFramework

  @genietools

  @vars Name begin
    
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

  route("/") do
    model = Stipple.init(Name)
    html(ui(model), context = @__MODULE__)
  end


  task = up(async=false) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app

end