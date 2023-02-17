


#Add the konva-viewer for iamge
Genie.Assets.add_fileroute(StippleUI.assets_config, "konva-viewer.js", basedir = pwd())
register_normal_element("k__viewer",context= @__MODULE__ )


@vars KViewerVar begin
    src::String = ""
    rois::Dict{String,Any} = Dict{String,Any}()
    tool_selected::Dict{String,Any} = Dict{String,Any}("tool"=>"") # TODO do no work 
end


"""
add a k__viewer to html interface
"""
function konvas_render(img_id,plugin_model)



  on(plugin_model.isready)  do isready
    isready || return 
    user_model = get_user_model()
    try
        if(isempty(user_model.list_image[][img_id].img_visual_path))
            plugin_model.src[]="/image?path="*user_model.list_image[][img_id].image_path
        else
            plugin_model.src[]="/image?path="*user_model.list_image[][img_id].img_visual_path
        end
        plugin_model.src[] *= "&v=" * string(user_model.list_image[][img_id].image_version)

        plugin_model.rois[] = user_model.list_image[][img_id].rois
        push!(plugin_model)
    catch e
        @error "isready went wrong" exception=(e, catch_backtrace())

    end
  end


  mydiv(class= "col",
  [
  k__viewer(
    tool_selected! = "tool_selected",
    src! = "src",
    var"v-model"="rois",
  ),
  #multi_dimentional_view_tool(user_model)
  ])
end




function deps() :: Vector{String}
    [
        Genie.Renderer.Html.script(src = "https://cdnjs.cloudflare.com/ajax/libs/konva/8.4.2/konva.js"),
        Genie.Renderer.Html.script(src = "https://unpkg.com/vue-konva@2.1.7/umd/vue-konva.js"),
      
        Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/konva-viewer.js"),
    ]
  end

route("/plugin/ZzImage/") do 



    img_id =  Genie.Requests.getpayload(:img_id,"/")
    plugin_model = Stipple.init(KViewerVar)

    Stipple.deps!(plugin_model, deps)

    page(plugin_model,class="container",
    [
        konvas_render(img_id,plugin_model)
    ]
    
    
    )
end