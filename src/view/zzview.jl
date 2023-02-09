


register_normal_element("k__viewer",context= @__MODULE__ )



function konvas_render(user_model)
  k__viewer(
    tool_selected! = "tool_selected",
    src! = "'/image?path='+((list_image[image_str].img_visual_path)?list_image[image_str].img_visual_path:list_image[image_str].image_path)+'&v='+list_image[image_str].image_version",
    var"v-model"="list_image[image_str].rois",
  )
end


function view_render(user_model)

  template([
  # StippleUI.imageview([],alt = "Format not suported",@iif("list_image[image_str].type==\"ZzImage\"");
  # src! = "'/image?path='+((list_image[image_str].img_visual_path)?list_image[image_str].img_visual_path:list_image[image_str].image_path)+'&v='+list_image[image_str].image_version",  
  # ),
  template([konvas_render(user_model)],@iif("list_image[image_str].type==\"ZzImage\""))
  ,
  #
  StipplePlotly.plot("removeEmpty(list_image[image_str].data)",layout =  PlotLayout(plot_bgcolor = "#333", title = PlotLayoutTitle(text = "Random numbers", font = Font(24))),config =  PlotConfig(),

  @iif("list_image[image_str].type==\"ZzPlot\"") 
  )
  ]
  )
end


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


  function image_list_layout(user_model)

    # on(user_model.selected_visual_plugin) do _
    #   if(user_model.selected_image[]!="" && user_model.selected_visual_plugin[]!="")
      
    #     execute_plugin(user_model,Symbol(user_model.selected_visual_plugin[]))
    #   end
      
    # end
    on(user_model.selected_image) do _
  
  
        try
          for (key, pipe) in all_pipeline()
            for node in pipe.nodes 
                process= node.process
  
                # save all param for previous_selected_image
                param = param_generator(user_model,pipe.name,process.name,process.Param)
                if(user_model.previous_selected_image != "")
                user_model.param_image_cache[user_model.previous_selected_image*"_"*pipe.name*"_"*process.name] = param
                end
                # restore if exist
                if haskey(user_model.param_image_cache,user_model.selected_image[]*"_"*pipe.name*"_"*process.name)
                  
                  param_seter(user_model,
                  user_model.param_image_cache[user_model.selected_image[]*"_"*pipe.name*"_"*process.name],
                  pipe.name,process.name
                  )
                end
            end
          end     
      
      catch e 
          @error "Error in selected_image" exception=(e, catch_backtrace())
        return nothing
        end
  
  
  
      user_model.previous_selected_image = user_model.selected_image[]
    end


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
              "Visual_execute=!Visual_execute;(image_viewer[0].indexOf(image_id)==-1)?(image_viewer[0].push(image_id),tabs_model[0]=image_id):false"
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