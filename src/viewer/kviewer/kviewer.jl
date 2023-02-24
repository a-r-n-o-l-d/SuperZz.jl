


#Add the konva-viewer for iamge
Genie.Assets.add_fileroute(StippleUI.assets_config, "konva-viewer.js", basedir = pwd())
register_normal_element("k__viewer",context= @__MODULE__ )


@vars KViewerVar begin
    src::String = ""
    rois::Dict{String,Any} = Dict{String,Any}()
    tool_selected::Dict{String,Any} = Dict{String,Any}("tool"=>"") # TODO do no work 



    slide_v::Vector{Int} = [1]
    slide_step_v::Vector{Int} = [1]
    slide_min_v::Vector{Int} =  [1]
    slide_max_v::Vector{Int} = [1]



end

Stipple.@kwredef struct userdata
    image::Any = nothing 
    zzimage::ZzImage = ZzImage()
end


function dimention_getter(plugin_model,plugin_model2)

    image = plugin_model2.image
    
    @info "dimention_getter : $(typeof(image))"


    values =  plugin_model.slide_v

    min_field = plugin_model.slide_min_v

    max_field = plugin_model.slide_max_v

    min_field[]=[Tuple(first(CartesianIndices(axes(image)[3:end])))...]
    max_field[]=[Tuple(last(CartesianIndices(axes(image)[3:end])))...]
    plugin_model.slide_step_v[]=[Tuple(step(CartesianIndices(axes(image)[3:end])))...]



    nva = vcat([v for v in values[] ] , [ 1 for _ in 1:(length(axes(image)[3:end])-length(values[])) ]  ) 
    resize!(nva,length(axes(image)[3:end])) 
    @warn nva "is strange"
    @debug max_field[] min_field[]
    @info "image exes" axes(image)
    nva = clamp.(nva,min_field[],max_field[])

    # update only if strictly needed
    @info "$(values[]) $nva"
    if values[] != nva
        values[]=nva
    end

    
    #push!(user_model)
end

function slider_extract(plugin_model,plugin_model2)
    ima =  Base.view(plugin_model2.image,:,:,plugin_model.slide_v[]...)

    add_data_list(plugin_model2.zzimage.img_id,plugin_model2.zzimage.img_name,ima,true)
    update_image(plugin_model,plugin_model2.zzimage.img_id)
end

function html_slider(plugin_model)

    
    return q__slider([],min! ="slide_min_v[index]",max! ="slide_max_v[index]" ,
    step! ="slide_step_v[index]",
    label = "",
    label__always = "",
    @bind("slide_v[index]"),
    key! = "index",
    #value! = "$(flat_name)_v[index]",
    @recur("(v,index) in slide_v")
    )
  end



function update_image(plugin_model,img_id)
    user_model = get_user_model()
    try
        src = "" 
        if(isempty(user_model.list_image[][img_id].img_visual_path))
            src="/image?path="*user_model.list_image[][img_id].image_path
        else
            src="/image?path="*user_model.list_image[][img_id].img_visual_path
        end
        src *= "&v=" * string(user_model.list_image[][img_id].image_version)

        #if src != plugin_model.src[]
            plugin_model.src[] = src
        #end

        if plugin_model.rois[] != user_model.list_image[][img_id].rois
            plugin_model.rois[] = user_model.list_image[][img_id].rois
                    #push!(plugin_model)
        end



    catch e
        @error "isready went wrong" exception=(e, catch_backtrace())

    end
end

"""
add a k__viewer to html interface
"""
function konvas_render(img_id,plugin_model)

  um = get_user_model()

  @async begin
    plugin_model2 = userdata(load_data(um.list_image[][img_id]),um.list_image[][img_id])
    dimention_getter(plugin_model,plugin_model2)

    slider_extract(plugin_model,plugin_model2)
    on(plugin_model.slide_v) do _
        @info "slider is update"
        slider_extract(plugin_model,plugin_model2)
    end
  end 

  on(plugin_model.isready)  do isready
     isready || return 
     update_image(plugin_model,img_id)
  end
  
  on(um.list_image) do _
    @info "list_image is update may this one two"
      update_image(plugin_model,img_id)
   end

  mydiv(class= "col",
  [
  k__viewer(
    tool_selected! = "tool_selected",
    src! = "src",
    var"v-model"="rois",
  ),
  html_slider(plugin_model)
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

  Stipple.deps!("zzvew", deps)

route("/plugin/ZzImage/") do 



    img_id =  Genie.Requests.getpayload(:img_id,"/")
    plugin_model = Stipple.init(KViewerVar)

    update_image(plugin_model,img_id)


    page(plugin_model,class="container",
    [
        konvas_render(img_id,plugin_model)
    ]
    
    
    )
end