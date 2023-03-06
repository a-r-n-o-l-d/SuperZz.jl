
#Add the konva-viewer for iamge
#Genie.Assets.add_fileroute(StippleUI.assets_config, "konva-viewer.js", basedir = pwd())

Genie.Assets.add_fileroute(StippleUI.assets_config, "leaflet-viewer.js", basedir = pwd())


register_normal_element("l__viewer",context= @__MODULE__ )

#register_normal_element("k__viewer",context= @__MODULE__ )


# @vars KViewerVar begin
#     src::R{String} = ""
#     rois::R{Dict{String,Any}} = Dict{String,Any}()
#     tool_selected::R{Dict{String,Any}} = Dict{String,Any}("tool"=>"") # TODO do no work 


#     properties::R{Dict{String,Any}} = Dict{String,Any}()

#     slide_v::R{Vector{Int}} = [1]
#     slide_step_v::R{Vector{Int}} = [1]
#     slide_min_v::R{Vector{Int}} =  [1]
#     slide_max_v::R{Vector{Int}} = [1]


#     export_as_roi_or_set_background::R{Bool} = false


#     type::R{String} = ""
# end

mutable struct KViewerVar <: Stipple.ReactiveModel
                    #= /home/bgirard/.julia/packages/Stipple/qnyBY/src/stipple/reactivity.jl:345 =#
                    channel__::String
                    _modes::Stipple.LittleDict{Symbol, Any}
                    isready::Stipple.R{Bool}
                    isprocessing::Stipple.R{Bool}
                    src::R{String}
                    rois::R{Dict{String, Any}}
                    tool_selected::R{Dict{String, Any}}
                    properties::R{Dict{String, Any}}
                    slide_v::R{Vector{Int}}
                    slide_step_v::R{Vector{Int}}
                    slide_min_v::R{Vector{Int}}
                    slide_max_v::R{Vector{Int}}
                    export_as_roi_or_set_background::R{Bool}
                    type::R{String}
end

KViewerVar(; channel__ = Stipple.channelfactory(), _modes = Stipple.LittleDict{Symbol, Any}(), isready = false, isprocessing = false, src = "", rois = Dict{String, Any}(), tool_selected = Dict{String, Any}("tool" => ""), properties = Dict{String, Any}(), slide_v = [1], slide_step_v = [1], slide_min_v = [1], slide_max_v = [1], export_as_roi_or_set_background = false, type = "") = begin
                    #= util.jl:493 =#
                    KViewerVar(channel__, _modes, isready, isprocessing, src, rois, tool_selected, properties, slide_v, slide_step_v, slide_min_v, slide_max_v, export_as_roi_or_set_background, type)
end

delete!.(Ref(Stipple.DEPS), filter((x->begin
                    x isa Type && x <: KViewerVar
                end), keys(Stipple.DEPS)))

Stipple.Genie.Router.delete!(Symbol(Stipple.routename(KViewerVar)))





Stipple.@kwredef struct userdata
    image::Any = nothing 
    zzimage::ZzImage = ZzImage()
end

function properties_extract(plugin_model,plugin_model2)
    image = plugin_model2.image
    if hasmethod(properties,Tuple{typeof(image)})

        prop = Dict{String,Any}()
        for (k,v) in  properties(image)
            if(!isnothing(v))
                prop[String(k)] = v
            end
        end
        plugin_model.properties[] = prop
    end
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

    
    #push!(plugin_model)
end

function slider_extract(plugin_model,plugin_model2)

    @info "slider_extract" plugin_model.slide_v[]

    if isempty(plugin_model.slide_v[])
        return
    end
    ima =  Base.view(plugin_model2.image,:,:,plugin_model.slide_v[]...)

    add_data_list(plugin_model2.zzimage.img_id,plugin_model2.zzimage.img_name,ima,true)
    update_image(plugin_model,plugin_model2.zzimage.img_id)
end

function html_slider(plugin_model)

    
    return q__slider(class="q-pa-md",[],min! ="slide_min_v[index]",max! ="slide_max_v[index]" ,
    step! ="slide_step_v[index]",
    label = "",
    label__always = "",
    @bind("slide_v[index]"),
    key! = "index",
    #value! = "$(flat_name)_v[index]",
    @recur("(v,index) in slide_v")
    )
  end

  function html_properties(plugin_model)

    
    return mydiv(["{properties}"])
  end

function html_button(plugin_model)
    on(plugin_model.export_as_roi_or_set_background) do _


        if plugin_model.type[]=="ZzRoi"
            s =  zzview_select_by_user(ZzImage)

            @info plugin_model.export_as_roi_or_set_background 
            @info s
            if length(s)>0
                zzselec = s[1]
                if(isempty(zzselec.img_visual_path))
                    src="/image?path="*zzselec.image_path
                else
                    src="/image?path="*zzselec.img_visual_path
                end
                src *= "&v=" * string(zzselec.image_version)
                plugin_model.src[] = src
            end
        end
    end

    return q__btn("export_as_roi_or_set_background",@click("export_as_roi_or_set_background=!export_as_roi_or_set_background"))
    
end

function zzimage_load(plugin_model,img_id)

    um = get_user_model()

    plugin_model2 = userdata(load_data(um.list_image[][img_id]),um.list_image[][img_id])


    properties_extract(plugin_model,plugin_model2)
    dimention_getter(plugin_model,plugin_model2)

    slider_extract(plugin_model,plugin_model2)
    on(plugin_model.slide_v) do _
        @info "slider is update"
        slider_extract(plugin_model,plugin_model2)
    end
end


function update_image(plugin_model,img_id)
    user_model = get_user_model()

    @info "Update image $img_id"
    try
        if plugin_model.rois[] != user_model.list_image[][img_id].rois
            @info "rois updated" user_model.list_image[][img_id].rois    
            plugin_model.rois[] = user_model.list_image[][img_id].rois

            #push!(plugin_model,:rois)
            #push!(plugin_model)
        end

        src = "" 
        if plugin_model.type[] == "ZzImage"
            if(isempty(user_model.list_image[][img_id].img_visual_path))
                src="/image?path="*user_model.list_image[][img_id].image_path
            else
                src="/image?path="*user_model.list_image[][img_id].img_visual_path
            end
            src *= "&v=" * string(user_model.list_image[][img_id].image_version)

            if src != plugin_model.src[]
                plugin_model.src[] = src
            end
        else
            image =  fill(RGB(0,0,0),(2048,2048))
            filename = START_PATH_FOR_MEMORY*"backgound"*img_id*".png"
            buf = IOBuffer()
            PNGFiles.save(buf, image)
            data = take!(buf)
            save(File(filename,data))

            plugin_model.src[] = "/image?path="*filename
            if src != plugin_model.src[]
                plugin_model.src[] = src
            end
        end
        #end





    catch e
        @error "isready went wrong" exception=(e, catch_backtrace())

    end
end

"""
add a k__viewer to html interface
"""
function konvas_render(img_id,plugin_model)

  um = get_user_model()


  on(plugin_model.isready)  do isready
     isready || return 

     @info "kviewer is ready"
     plugin_model.type[] =  plugin_model.type[]
     try
        update_image(plugin_model,img_id)
        if plugin_model.type[] == "ZzImage"
            zzimage_load(plugin_model,img_id)
        end
    catch e
    @error "is ready " exception=(e, catch_backtrace())

    end


    # on(plugin_model.rois) do _
    #     um.list_image[][img_id].rois =  plugin_model.rois[]
    # end



  end
  
  on(um.list_image) do _
    @info "list_image is update may this one two"
      update_image(plugin_model,img_id)
   end

  mydiv(class= "fit",
  [
#   k__viewer(
#     tool_selected! = "tool_selected",
#     src! = "src",
#     var"v-model"="rois",
#   ),
  l__viewer(
    tool_selected! = "tool_selected",
    src! = "src",
    var"v-model"="rois",
  ),
  html_slider(plugin_model),
  html_button(plugin_model)
  #multi_dimentional_view_tool(user_model)
  ])
end




function deps_kviewer() :: Vector{String}
    [
        #Genie.Renderer.Html.script(src = "https://cdnjs.cloudflare.com/ajax/libs/konva/8.4.2/konva.js"),
        #Genie.Renderer.Html.script(src = "https://unpkg.com/vue-konva@2.1.7/umd/vue-konva.js"),
      

        Genie.Renderer.Html.script(src = "https://unpkg.com/leaflet@1.9.3/dist/leaflet.js"),
        Genie.Renderer.Html.script(src = "https://unpkg.com/vue2-leaflet@2.7.1"),

        Genie.Renderer.Html.script(src = "https://unpkg.com/@geoman-io/leaflet-geoman-free@2.14.2/dist/leaflet-geoman.min.js"),
        #Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/konva-viewer.js"),
        Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/leaflet-viewer.js"),
    ]
  end

  
Stipple.deps!(KViewerVar, deps_kviewer)

function routing_page(img_id,type)
    plugin_model = Stipple.init(KViewerVar)
    plugin_model.type[] = type


    page(plugin_model,class="container",style="height:100%;",
    prepend= [
        Stipple.Elements.stylesheet("https://unpkg.com/leaflet@1.9.3/dist/leaflet.css"),
        Stipple.Elements.stylesheet("https://unpkg.com/@geoman-io/leaflet-geoman-free@2.14.2/dist/leaflet-geoman.css")
    ],
    [


        konvas_render(img_id,plugin_model)
    ]
    
    
    )
end

route("/plugin/ZzImage/") do 
    img_id =  Genie.Requests.getpayload(:img_id,"/")
    routing_page(img_id,"ZzImage")
end

route("/plugin/ZzRoi/") do 
    img_id =  Genie.Requests.getpayload(:img_id,"/")
    routing_page(img_id,"ZzRoi")
end