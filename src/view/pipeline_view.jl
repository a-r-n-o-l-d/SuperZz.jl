include("html_param.jl")



function process_render(user_model,pipeline,node)
  process=node.process
  @info "generate html for $process"
  paramtype = process.Param
  list = []

  for (field_name,field_type) in zip(fieldnames(paramtype),fieldtypes(paramtype))
       @info field_name
       if startswith(string(field_name),"channel") || startswith(string(field_name),"_") || startswith(string(field_name),"isready")  || startswith(string(field_name),"isprocessing")
         continue
       end
       push!(list,html_param_items(user_model,field_type(),pipeline.name*"_"*process.name,field_name,pipeline,node))
  end

  on(getfield(user_model,Symbol(string(pipeline.name)*"_"*process.name*"_execute"))) do _
    @info "execute is call for process $(process.name)"
    execute_pipeline(user_model,pipeline,node)
  end

  return q__card(class="q-pa-md", [p("Param for Process  : "*string(process.name)),mydiv(list),

    (!pipeline.is_visual) ? StippleUI.btn("Execute ",@click(string(pipeline.name)*"_"*process.name*"_execute = !"*string(pipeline.name)*"_"*process.name*"_execute")) : "" 
  
  ])
end


function pipeline_render(user_model,pipeline)


    on(getfield(user_model,Symbol(string(pipeline.name)*"_execute"))) do _
      @info "execute is call for pipeline $(pipeline.name) "
      execute_pipeline(user_model,pipeline,nothing)
    end
  
  if pipeline.is_visual || length(pipeline.nodes) == 1
    return      mydiv(class="q-pa-md",[
      process_render(user_model,pipeline,n)
      for n in pipeline.nodes
      ])
  else
  
    q__card([
      "PIPELINE : "*pipeline.name,
      mydiv(class="q-pa-md",[
        process_render(user_model,pipeline,n)
      for n in pipeline.nodes
      ]),
  
      ((!pipeline.is_visual) ? StippleUI.btn("Execute Pipeline ",@click(string(pipeline.name)*"_execute = !"*string(pipeline.name)*"_execute")) : "")
    ])
    end
  end
  


function pipeline_list(user_model)
    mydiv(class="fit overflow-auto",
    [
      q__input([],filled = "",label = "Filter" ,@bind("filter")),
      mydiv(
        [
          mydiv([ pipeline_render(user_model,p)],
          
          var"v-show"="'$k'.toLowerCase().indexOf(filter.toLowerCase())>-1"
          ) for (k,p) in pipelines()
        ]
      )
  
  
    ]
  
    )
  end