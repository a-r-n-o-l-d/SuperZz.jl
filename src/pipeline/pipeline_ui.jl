
"""
Difnia a plugin that manage pipeline

pipeline are simple chained function that easy add to the interface witout any boilporate code

Sample:

function gray(input::InputImage,param::NoParam)
    return Gray.(input.image)
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end
single_process(gray)

Will genearte and add widget to web ui pipline and when user cliak on run button will can gray

Each funton must finis with a param type param to genearte html code to web ui for ask param to user



"""



include("model.jl")

include("pipeline_view.jl")

include("visual_pipeline.jl")

PipelineStructGenerator()

@vars PipelineModel begin

    filter::String = ""

    previous_selected_image::String = "" , NON_REACTIVE

    param_image_cache::Dict{String,Any} = Dict{String,Any}() , NON_REACTIVE # cache is not reactive

    @mixin PipelineFlat 

end




function ui(plugin_model::PipelineModel)
    user_model = get_user_model()

    on(user_model.tabs_model) do test 

      @info "tabs_model update" test
      for m in get_user_model().tabs_model[]
          for (k,v) in user_model.list_image[]
              if k==m
                  execute_pipeline(plugin_model,VisualPipeLine,nothing,v)
              end
          end
      end
  
  end

    on(user_model.selected_image) do _
  
  
        try
          for (key, pipe) in all_pipeline()
            for node in pipe.nodes 
                process= node.process
    
                # save all param for previous_selected_image
                param = param_generator(plugin_model,pipe.name,process.name,process.Param)
                if(plugin_model.previous_selected_image != "")
                    plugin_model.param_image_cache[plugin_model.previous_selected_image*"_"*pipe.name*"_"*process.name] = param
                end
                # restore if exist
                if haskey(plugin_model.param_image_cache,user_model.selected_image[]*"_"*pipe.name*"_"*process.name)
                  
                  param_seter(plugin_model,
                  plugin_model.param_image_cache[user_model.selected_image[]*"_"*pipe.name*"_"*process.name],
                  pipe.name,process.name
                  )
                end
            end
          end     
      
      catch e 
          @error "Error in selected_image" exception=(e, catch_backtrace())
        return nothing
        end
    
    
    
        plugin_model.previous_selected_image = user_model.selected_image[]
    end

    [
  
      page(plugin_model,class="container",
        prepend=[

        #Stipple.Elements.stylesheet("https://cdn.jsdelivr.net/npm/vue-draggable-resizable@2.3.0/dist/VueDraggableResizable.css")
        ]
        ,
       [
        mydiv(class="column  fit no-wrap justify-between",[
            pipeline_list(plugin_model),
           q__card([
            " Visual param",
           pipeline_render(plugin_model,VisualPipeLine)
           ])
           ]
          )
       ])
  
    ]
  
end

route("/plugin/pipeline") do 
    plugin_model = Stipple.init(PipelineModel)
    html(ui(plugin_model), context = @__MODULE__)
end

push!(PLUGIN_LIST,"pipeline")