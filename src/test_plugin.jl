

function ran()
    run_pipeline_with_error_check() do 
        zz_image = zzview_select_by_user()
        image = load_data(zz_image)

        image = Gray.(image)

        add_data_list(derive_name("Plugin_crroper",zz_image)...,image)
    end
end

@vars MyVar begin
    run::Bool = false
end


function ui(plugin_model::MyVar)
    on(plugin_model.run) do _

        ran()


    end

    [
  
      page(plugin_model,class="container",
        prepend=[

        #Stipple.Elements.stylesheet("https://cdn.jsdelivr.net/npm/vue-draggable-resizable@2.3.0/dist/VueDraggableResizable.css")
        ]
        ,
       [
        mydiv(q__card([ q__btn(["Run"],@click("run=!run"))]))
       ])
  
    ]
  
end


route("/plugin/gray") do 
    plugin_model = Stipple.init(MyVar)
    html(ui(plugin_model), context = @__MODULE__)
end

push!(PLUGIN_LIST,"gray")
  