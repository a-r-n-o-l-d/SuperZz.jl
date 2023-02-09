

#html_param_items genere le code html pour que l'utisatuer rentre une valeur pour le paramtre d'un pipeline



function html_param_items(user_model,::Roi,symbol_model,field_name,pipeline,node)


  flat_name = string(symbol_model)*"_"*string(field_name)

    mydiv(
      [
       q__btn(["Roi "],@click("tool_selected[\"tool\"] = \"roi\";tool_selected[\"setter\"]=(value)=>$(flat_name)_name=value")),
       "selected roi {{ $(flat_name)_name }}"
      ]

   )
end

function html_param_items(user_model,::Slider,symbol_model,field_name,pipeline,node)

  flat_name = string(symbol_model)*"_"*string(field_name)
    on(getfield(user_model,Symbol(flat_name*"_v"))) do _
          @info "model param is update"
    end

    return StippleUI.slider(range(0,stop=1.0,step=0.1),Symbol(flat_name*"_v"))
end


function html_param_items(user_model,::DimentionSlider,symbol_model,field_name,pipeline,node)

  flat_name = string(symbol_model)*"_"*string(field_name)

  on(getfield(user_model,Symbol(flat_name*"_v"))) do _
        @info "param $(flat_name)_v is update"
      
        if pipeline.is_visual
          execute_pipeline(user_model,pipeline,node)
        end
  end

  return q__slider([],min! ="$(flat_name)_min_v[index]",max! ="$(flat_name)_max_v[index]" ,
  step! ="$(flat_name)_step_v[index]",
  label = "",
  label__always = "",
  @bind("$(flat_name)_v[index]"),
  key! = "index",
  #value! = "$(flat_name)_v[index]",
  @recur("(v,index) in $(symbol_model)_$(field_name)_v")
  )
end

function html_param_items(user_model,par::String)
  p("Tool for String")
end

