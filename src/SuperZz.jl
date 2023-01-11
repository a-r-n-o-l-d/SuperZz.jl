module SuperZz
using Genie, Genie.Renderer.Html # some app deps
using GenieAutoReload
const mydiv = Genie.Renderer.Html.div
using Stipple, StippleUI, Stipple.ReactiveTools
using Images, FileIO

import Genie.Renderer.Html: HTMLString, normal_element, register_normal_element


register_normal_element("q__header",context= @__MODULE__ )

include("model.jl")

# Write your package code here.

# function plugin_loading()
#     using FromFile: @from
#     plugins = []
#     map(requested_plugins) do plugin_path
#         plugin_name = splitext(splitdir(plugin_path)[2])[1]
#         plugin = Symbol(plugin_name)
#         @eval @from $plugin_path import $plugin
#         @eval $plugin.activate()
#         push!(plugins, plugin)
#     end
# end
const CSS = style("""
     .menubackgroud
     {
        background-color: #74992e;
     
     }
     """
     )



const IMG_PATH = "/dev/shm/currentZz.png"

Stipple.@kwdef mutable struct ZzImage

  image = NaN
  path  = ""

end


function teset_image()
  @info "load test image"
  path = "/home/bgirard/Téléchargements/P1100119-2.jpg"
  img = load(path)
  save(IMG_PATH,img)
  
end
teset_image()


current_image = ZzImage()

function plugin_dict()


  return Dict("cropper"=>(Input,Param,Output))
end

function plugin_dict_pram()

  return Dict(:cropper=>Param)
end


function PluginStructGenerator()  
    
  fields = [ ]
  for (key, value) in plugin_dict_pram() 

    fields_sub_type = []
    for (field_name,field_type) in zip(fieldnames(value),fieldtypes(value))
      push!(fields_sub_type,
      :(@mixin $(Symbol(string(field_name)*"_"))::$(field_type))
      )
    end

  eval(quote
    Stipple.@kwdef struct $(Symbol(string(value)*"Model"))
      $(fields_sub_type...) 
        end
    end)
    @info eval(:($(Symbol(string(value)*"Model"))))
    push!(fields,
    :(@mixin $(Symbol(string(key)*"_"))::$(Symbol(string(value)*"Model")))
    )
  end

  eval(quote
      Stipple.@kwdef struct Plugins
        $(fields...) 
          end
   end)
end

PluginStructGenerator()

@vars Model begin
  
    update_image::R{String} = "/currentimage"
    leftDrawerOpen::R{Bool} = true

    @mixin Plugins
end




function html_param_items(par::Roi,symbol_plugin,field_name)

    p("Tool for ROI")
end

function html_param_items(par::Slider,symbol_plugin,field_name)

    on(getfield(model,Symbol(string(symbol_plugin)*"_"*string(field_name)*"_v"))) do _
          @info "model param is update"
          @info  model.cropper_theata_v
    end
    on(par.v) do _
      @info "model param2 is update"
      @info  par
    end
    return StippleUI.slider(range(0,stop=10,step=1),Symbol(string(symbol_plugin)*"_"*string(field_name)*"_v"))
end

function html_param_items(par::String)
  p("Tool for String")
end

function html_param(symbol_plugin,type_pram_plugin)
    global model
    @info "generate html for $symbol_plugin"
    paramtype = type_pram_plugin
    list = []

    for (field_name,field_type) in zip(fieldnames(paramtype),fieldtypes(paramtype))
         @info field_name
         if startswith(string(field_name),"channel") || startswith(string(field_name),"_") || startswith(string(field_name),"isready")  || startswith(string(field_name),"isprocessing")
           continue
         end
         push!(list,html_param_items(field_type(),symbol_plugin,field_name))
    end
    return list
end

function main_page()
    
    mydiv(class="",[
    
    StippleUI.imageview(src=:update_image, style = "height: 100%; max-width: 100%" )

     ]
    )
end

function menupage()
    mydiv(class="col-3",[
     p("Menu"),
     mydiv(html_param(:cropper,Param))

     #map(p -> html_param(p[3]),plugin_list())
     
     ]
    )
end

function page_loyout(content,drawer)
    StippleUI.layout(view="hHh lpR fFf",[
      q__header(class="bg-primary text-white" , reveal="",bordered="",
      [
        StippleUI.q__toolbar([
            StippleUI.btn("", dense="", flat="", round="",icon="menu",@click("leftDrawerOpen=!leftDrawerOpen"))

        ]

        )

      ]),
      StippleUI.q__drawer(show__if__above="",side="left",bordered="",v__model="leftDrawerOpen",
        drawer
      ),
      StippleUI.q__page__container(
      content
      )


    ])
end

function ui(model)

  [
    CSS,
    page(model,class="container", [
      page_loyout([
             main_page()

      ],
      [
        menupage()

      ])


  ] ),

  Genie.Assets.channels_support(), # auto-reload functionality relies on channels
  GenieAutoReload.assets()
  ]
end


route("/") do 
  global model
  model = Stipple.init(Model)
  html(ui(model), context = @__MODULE__)
end


route("/currentimage") do 
    Genie.Router.serve_file(IMG_PATH)
end
 

# using Revise
# faire fonciotn start and stop 
Genie.config.websockets_server = true
GenieAutoReload.autoreload(joinpath(pwd(),"src"),devonly = false)
up() # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app



end
