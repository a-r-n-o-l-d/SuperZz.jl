





@vars PlotViewerVar begin
data::Vector{Any} = Vector{Any}()
end



function plot_render(img_id,plugin_model)



  on(plugin_model.isready)  do isready
    isready || return 
    user_model = get_user_model()
    try
        @info plugin_model
        plugin_model.data[] = user_model.list_image[][img_id].data
        push!(plugin_model)
    catch e
        @error "isready went wrong" exception=(e, catch_backtrace())

    end
  end


  mydiv(class= "col",
  [
  StipplePlotly.plot("removeEmpty(data)",layout =  PlotLayout(plot_bgcolor = "#333", title = PlotLayoutTitle(text = "Random numbers", font = Font(24))),config =  PlotConfig(),
  )
  #multi_dimentional_view_tool(user_model)
  ])
end

Stipple.js_methods(::PlotViewerVar) = """ 
removeEmpty(arrr) {
  return arrr.map(obj=> Object.fromEntries(Object.entries(obj).filter(([_, v]) => v != null)));
}
"""


route("/plugin/ZzPlot/") do 

    img_id =  Genie.Requests.getpayload(:img_id,"/")
    plugin_model = Stipple.init(PlotViewerVar)


    page(plugin_model,class="container",
    [
        plot_render(img_id,plugin_model)
    ]
    
    
    )
end