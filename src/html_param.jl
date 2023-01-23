
include("model.jl")

function html_param_items(user_model,par::Roi,symbol_plugin,field_name)

    p("Tool for ROI")
end

function html_param_items(user_model,par::Slider,symbol_plugin,field_name)

    on(getfield(user_model,Symbol(string(symbol_plugin)*"_"*string(field_name)*"_v"))) do _
          @info "model param is update"
          @info  user_model.cropper_theata_v
    end

    return StippleUI.slider(range(0,stop=10,step=1),Symbol(string(symbol_plugin)*"_"*string(field_name)*"_v"))
end

function html_param_items(user_model,par::String)
  p("Tool for String")
end

