using GenieFramework


const mydiv = Genie.Renderer.Html.div

@vars Model1 begin
    splitter_model::Int = 100

end

@vars Model2 begin
    splitter_model::Int = 0

end
function page_loyout(user_model)

      
    on(user_model.splitter_model) do _
        try
        print("TET "*string(user_model.splitter_model[]))   
    catch e
          @error "Error in pipeline" exception=(e, catch_backtrace())
    end     
    end


    mydiv([

    slider(range(0,stop=100.0,step=1),:splitter_model)


    ])

  end


function ui(user_model)

    [
  
      page(user_model,class="container",
        prepend=[

        #Stipple.Elements.stylesheet("https://cdn.jsdelivr.net/npm/vue-draggable-resizable@2.3.0/dist/VueDraggableResizable.css")
        ]
        ,
       [
        page_loyout(user_model)
       ])
  
    ]
  
end

global_user_model = Stipple.init(Model1)
route("/end1") do 

  html(ui(global_user_model), context = @__MODULE__)
end

route("/end2") do 
    local_user_model = Stipple.init(Model2)
    html(ui(local_user_model), context = @__MODULE__)
end
  

@genietools

up(async=isinteractive()) 