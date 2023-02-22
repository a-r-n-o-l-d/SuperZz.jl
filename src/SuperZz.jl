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


# 1) les commentaire

#2) Visialiton : 
# - slice
# - LUT 
# ZZ IMAGE SLIDER
# affihcer les metadata si existe

# TODO :  faire UN roi manager avec des ROI SET et un front image

# Plugin de test : 
# Sepapez les cannaux 
# Filtre gaussien





# loaded image

include("custom_log.jl")

"""
  Define shortcut for html.div
"""
const mydiv = Genie.Renderer.Html.div

#    permet de d'ulister des balise html non definie dans genis par default
register_normal_element("q__header",context= @__MODULE__ )
register_normal_element("template",context= @__MODULE__ )


include("memory_files.jl")

include("view/zzview.jl")


include("plugin.jl")



# global env structure
struct Env
  user_model

end

"""
create dummy data to delete 
"""
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


"""
Main data exachege with main web ui vue.js app 
"""
@vars Model begin
   
    leftDrawerOpen::Bool = true
    rightDrawerOpen::Bool = true

    image_viewer::Vector{Vector{String}} = demo_image_viewer() # image show is spliter 
 
    list_image::Dict{String,ZzView} = demo_image() # list of image loaded in memeory 

    splitter::Int = 100 # spliter proporitn between two image
    tabs_model::Vector{String} = ["SampleZZ",""] # what iamge are show in each spliter



    selected_image::String = "" # iamge selected by user


    debug::String = "" # show string to debug 

    files_tree::Vector{Dict{String,Any}} = [Dict("label"=>"/","path"=>"/","lazy"=>true)] # see remote file explorer
    files_selected::String = ""

end


include("remote_file_explorer.jl")

include("file_upload.jl")


include("view/custom_method.jl")

include("view/layout.jl")

#custom plugin Pipeline
include("pipeline/pipeline_ui.jl")


# add a test plugiin 
include("test_plugin.jl")


Genie.Assets.add_fileroute(StippleUI.assets_config, "iframe.js", basedir = pwd())

function deps_superzz() :: Vector{String}
  [

    
      Genie.Renderer.Html.script(src = "/stippleui.jl/master/assets/js/iframe.js"),
  ]
end




"""
 Create Model for sync data with vue js
"""
user_model = Stipple.init(Model)
Stipple.deps!("iframe", deps_superzz)

route("/") do 
  ui(user_model)
end

"""
Defnien global vaiable for all plugin 
"""
PLUGIN_ENV = Env(user_model)



"""
Start futnion to lauch this module 
"""
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
