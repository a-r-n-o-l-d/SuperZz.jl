
"""
ZzView are item diplayed in html web ui
 -     img_id::String =""
 -     img_name::String
 Must be present 

""" 
abstract type  ZzView

end

"""
ZzImage is define image type to show in web ui
"""
Base.@kwdef mutable struct ZzImage <: ZzView
    img_id::String =""
    image_path::String = "" # paht in virtual moeyr or on fielsystem to raw image
    image_version::Int = 0 # to force navigoator to reload image
  
    img_visual_path::String = "" # path to show if image_path is not viewvable
  
    img_name::String = "" # name to print in web ui
  
    rois::Dict{String,Any} = Dict{String,Any}()

    
    type = "ZzImage"
  end
  
"""
 Define a plot to show in web ui on Plotly
"""
Base.@kwdef mutable struct ZzPlot <: ZzView
    img_id::String =""
    data::Vector{Any} = []
  
    img_name::String=""
    type = "ZzPlot"
  end
  
function Base.convert(::Type{T},value::Dict{String, Any}) where {T<:ZzView}
    try
      if value["type"] == "ZzImage"
        ZzImage(; Dict(zip(Symbol.(string.(keys(value))), values(value)))... ) 
      elseif value["type"] == "ZzPlot"
        ZzPlot(; Dict(zip(Symbol.(string.(keys(value))), values(value)))... )
      end
    catch e
      @error value
      @error "convert went wrong" exception=(e, catch_backtrace())
  
    end
    
end



include("../viewer/kviewer/kviewer.jl")
#include("../viewer/pl/kviewer.jl")


function multi_dimentional_view_tool(user_model)

end



# template([
#   # StippleUI.imageview([],alt = "Format not suported",@iif("list_image[image_str].type==\"ZzImage\"");
#   # src! = "'/image?path='+((list_image[image_str].img_visual_path)?list_image[image_str].img_visual_path:list_image[image_str].image_path)+'&v='+list_image[image_str].image_version",  
#   # ),
#   template([konvas_render(user_model)],@iif("list_image[image_str].type==\"ZzImage\""))
#   ,
#   #
#   StipplePlotly.plot("removeEmpty(list_image[image_str].data)",layout =  PlotLayout(plot_bgcolor = "#333", title = PlotLayoutTitle(text = "Random numbers", font = Font(24))),config =  PlotConfig(),

#   @iif("list_image[image_str].type==\"ZzPlot\"") 
#   )
#   ]
#   )


"""
Generate vue js code to select the viewer mapped to the zzView Type
"""
function view_render(user_model)

  return mydiv([iframe(
  frameborder="0",  
  src! = "'/plugin/'+list_image[image_str].type+'?img_id='+image_str",
  style="height: 100%;width:100%;border:none;")
  ],
  style = "height:100%;"
  )

end


"""
Generate vue js code to manage the spliter in image view
"""
function image_tabs(user_model,spliter_number)

    mydiv([
        q__tabs([
  
          q__tab([
            mydiv(class="row  items-center",[
  
                " {{list_image[image_str].img_name}} ",
                
                q__btn([],@click("image_viewer[$spliter_number].splice(index, 1)"),flat="", icon="close"),
  
                q__btn([],@click(
                  
            "split_image($spliter_number,index,image_str)"),flat="", icon="vertical_split")
            ])
  
  
          ],@recur("(image_str,index) in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id", key! = "list_image[image_str].img_id", @click(""))
  
        ],@bind("tabs_model[$spliter_number]"),dense="",narrow__indicator=""),
         q__tab__panels(
           [
             q__tab__panel([
  
            view_render(user_model)
  
            ],@click("selected_image=list_image[image_str].img_id"),key! = "list_image[image_str].img_id",@recur("image_str in image_viewer[$spliter_number]"),name! = "list_image[image_str].img_id"),
  
             q__tab__panel(["Select a iamge in tab"],name! ="''")
           ],
           @bind("tabs_model[$spliter_number]"),animated=""
         )
  
    ])
  
  end

"""
Generate code to show a list of zzView load in memeory 
"""
function image_list_layout(user_model)

    # on(user_model.selected_visual_plugin) do _
    #   if(user_model.selected_image[]!="" && user_model.selected_visual_plugin[]!="")
      
    #     execute_plugin(user_model,Symbol(user_model.selected_visual_plugin[]))
    #   end
      
    # end


    mydiv(class="q-pa-sm",
    [
      q__list([
  
        q__item(
        [
          q__item__section([
            q__input([],@bind("image.img_name"),dense=""),

          "{{(image.image_path != undefined && image.image_path.startsWith('inmemory'))?('in memory'):image.image_path}}"
          
          
          ],@click("selected_image=image_id"),class="cursor-pointer ",clickable="",v__ripple="")
  
          q__item__section([
            q__btn([],round="",icon="preview",
            @click(
              "selected_image=image_id;(image_viewer[0].indexOf(image_id)==-1)?(image_viewer[0].push(image_id),tabs_model[0]=image_id):false"
              )
            ),
            q__btn([],round="",icon="close",@click("delete_image(image_id)"))
  
            
            ],avatar="")
        ]
        ,
        key! = "image_id"
        ,
        @recur("(image,image_id) in list_image"),
        active! ="selected_image === image_id",
        active__class="active-link",
        )
  
      ],bordered="",padding=""),
  
  
      # q__list([
  
      #   q__item(
      #   [
      #     q__item__section([""*string(visul_plugin.first)])
  
      #   ],
      #   clickable="",
      #   v__ripple="",
      #   active! = "selected_visual_plugin == '"*string(visul_plugin.first)*"' ",
      #   active__class="active-link",
      #   @click("selected_visual_plugin = \""*string(visul_plugin.first) *"\" "),
      #   ) for visul_plugin in visual_plugin_list()
  
      # ],bordered="",padding=""),
    
  
    ])
    
  end

#Route to load image on get hhtp request 
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