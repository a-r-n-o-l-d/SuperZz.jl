module SuperZz

using Stipple
using GenieFramework
using FileIO
using HTTP
using PNGFiles
using Images
#import UUIDs
import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element
using LRUCache
#using Plots, 
using StatsBase


# TODO :  faire UN roi manager avec des ROI SET et un front image


# Plugin de test : 
# Sepapez les cannaux 
# Filtre gaussien

# ZZ IMAGE SLIDER

# Visialiton : 
# - slice
# - ZOOM 
# - LUT 


# loaded image

@info "SuperZZ Loaded"
include("custom_log.jl")

const mydiv = Genie.Renderer.Html.div

register_normal_element("q__header",context= @__MODULE__ )
register_normal_element("template",context= @__MODULE__ )


include("memory_files.jl")

include("view/zzview.jl")

include("model.jl")

include("plugin.jl")



# global env structure
struct Env
  user_model

end


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



@vars Model begin
   
    leftDrawerOpen::Bool = true
    rightDrawerOpen::Bool = true

    image_viewer::Vector{Vector{String}} = demo_image_viewer()

    list_image::Dict{String,ZzView} = demo_image()

    splitter::Int = 100
    tabs_model::Vector{String} = ["SampleZZ",""]

    tool_selected::Dict{String,Any} = Dict{String,Any}("tool"=>"")

    selected_image::String = ""


    debug::String = ""

    files_tree::Vector{Dict{String,Any}} = [Dict("label"=>"/","path"=>"/","lazy"=>true)]
    files_selected::String = ""

end







include("remote_file_explorer.jl")
include("file_upload.jl")


#   #


include("view/custom_method.jl")

include("view/layout.jl")

#custom plugin
include("pipeline/pipeline_ui.jl")

include("visual_pipeline.jl")

include("test_plugin.jl")

#@page() // for new vertion
user_model = Stipple.init(Model)
route("/") do 
  html(ui(user_model), context = @__MODULE__)
end


route("/image") do 
  @info  Genie.Requests.getpayload(:path,"")

  path = Genie.Requests.getpayload(:path,"")
  if(is_memory_file(path))
    file = get_file(path)

    serve_file(file)
  else
    Genie.Router.serve_file(path)
  end
end


PLUGIN_ENV = Env(user_model)


function start()
    @genietools
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
