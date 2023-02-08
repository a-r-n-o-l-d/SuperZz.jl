module SuperZz

using Stipple
using GenieFramework
using FileIO
using Images
#import UUIDs
import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element
using LRUCache
#using Plots, 
using StatsBase


@genietools

@info "SuperZZ Loaded"

Genie.Assets.add_fileroute(StippleUI.assets_config, "konva-viewer.js", basedir = pwd())

const mydiv = Genie.Renderer.Html.div
const UPLOAD_PATH = "/dev/shm/"
register_normal_element("q__header",context= @__MODULE__ )

register_normal_element("template",context= @__MODULE__ )


include("custom_log.jl")
include("zzimage.jl")
include("model.jl")

include("pipeline.jl")

include("visual_pipeline.jl")






  


# Plugin de test : 
# Sepapez les cannaux 
# Filtre gaussien

# Visialiton : 
# - slice
# - ZOOM 
# - LUT 


# loaded image





function demo_image()
  @info "load test image"
  path = "/home/bgirard/Téléchargements/P1100119-2.jpg"
  path2 = "/home/bgirard/Téléchargements/test.ome.tif"
  #img = load(path)
  dict = Dict{String,ZzView}("SampleZZ"=>ZzImage(
    image_path=path,
    img_id="SampleZZ",
    img_name="SampleZZ"
  )
  ,
  "ComplexSampleZZ"=>ZzImage(
    image_path=path2,
    img_id="ComplexSampleZZ",
    img_name="ComplexSampleZZ"
  )
  )
  dict["HistSampleZZ"] = ZzPlot(
    img_id="HistSampleZZ",data=histogram(convert(InputImage,dict["SampleZZ"]),NoParam()),
    img_name="HistSampleZZ"
  )

  return dict
end

function demo_image_viewer()

  [["SampleZZ"],[]]
end


PipelineStructGenerator()


@vars Model begin
   
    leftDrawerOpen::R{Bool} = true
    rightDrawerOpen::R{Bool} = true

    image_viewer::R{Vector{Vector{String}}} = demo_image_viewer()

    list_image::R{Dict{String,ZzView}} = demo_image()

    splitter::R{Int} = 100
    tabs_model::R{Vector{String}} = ["SampleZZ",""]

    tool_selected::R{Dict{String,Any}} = Dict{String,Any}("tool"=>"")

    selected_image::R{String} = ""
    previous_selected_image::String = ""

    debug::R{String} = ""

    filter::R{String} = ""

    files_tree::R{Vector{Dict{String,Any}}} = [Dict("label"=>"/","path"=>"/","lazy"=>true)]
    files_selected::R{String} = ""

    param_image_cache::Dict{String,Any} = Dict{String,Any}() # cache is not reactive

    @mixin PipelineFlat
end




include("view/zzview.jl")
include("view/pipeline_view.jl")

include("remote_file_explorer.jl")
include("file_upload.jl")


#   #


include("view/custom_method.jl")

include("view/layout.jl")




#@page() // for new vertion
user_model = Stipple.init(Model)
route("/") do 
  html(ui(user_model), context = @__MODULE__)
end


route("/image") do 
  @info  Genie.Requests.getpayload(:path,"")
  Genie.Router.serve_file(Genie.Requests.getpayload(:path,""))
end


 

function start()

# using Revise
# faire fonciotn start and stop 
Genie.config.websockets_server = true
#GenieAutoReload.autoreload(joinpath(pwd(),"src"),devonly = false)

# with_logger(zz_logger) do 

 up(async=isinteractive()) # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app

#end
end

Server.isrunning() || start()

end
