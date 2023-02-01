
using Stipple
# Pileline executor  
#
# 


struct PipelineProcess
        name::String
        f::Function
        Inputs::Vector{DataType}
        Output::DataType
        Param::DataType
        user_param_modifier::Union{Function,Nothing}

        PipelineProcess(n,f,i,o,p,u=nothing) = new(n,f,i,o,p,u)
end

Stipple.@kwdef mutable struct Cache
    is_dirty = true
    param = nothing
    data = nothing


    input_key = nothing
    input_value = nothing
end

mutable struct PipelineNode
    inputs::Vector{Union{PipelineNode,Any}}
    process::PipelineProcess
    output::Union{PipelineNode,Nothing}
    cached::Cache

    PipelineNode(i,p,o,c=Cache()) = new(i,p,o,c)

end

#UserInputNode = PipelineNode([])

Stipple.@kwdef struct Pipeline

    name::String
    nodes::Vector{PipelineNode}
    is_visual::Bool = false
       
end

include("test_pipeline.jl")

function pipelines()

    return Dict("croper"=>CropperPipeline,"Dimention"=>DimentionalPipeline,
    "histogram"=>histogramPipeline,
    "binarise"=>binarisePipeline,
    )
  end

function all_pipeline()
  return merge(pipelines(),Dict("visual"=>VisualPipeLine))
  
end


function PipelineStructGenerator()  
    
    fields = [ ]
    for (key, pipe) in all_pipeline()
        for node in pipe.nodes 
            process= node.process
            fields_sub_type = flat_reactive_struct(process.Param,string(pipe.name)*"_"*string(process.name)*"_")
        
            push!(fields_sub_type,
             :($(Symbol(string(pipe.name)*"_"*string(process.name)*"_"*"execute"))::R{Bool}=false)
            )
            push!(fields,fields_sub_type...)
        end
        push!(fields,
        :($(Symbol(string(pipe.name)*"_"*"execute"))::R{Bool}=false)
       )
    end
  
    eval(quote
        Stipple.@kwdef struct PipelineFlat
          $(fields...) 
            end
     end)
  end


  function param_generator(user_model,pipeline_name,process_name,paramtype)

    pram = unflat_reactive_struct(paramtype,user_model,string(pipeline_name)*"_"*process_name*"_") 
    @info "Generate param form user model" param
    return pram
  end

  function param_seter(user_model,param,pipeline_name,process_name)

    flat_var_reactive_struct(
    user_model,
    param,
    pipeline_name*"_"*process_name*"_"
    )

  end
  
  
  function select_image(user_model)
      for (k,v) in user_model.list_image[]
          if k==user_model.selected_image[]
              return v
          end
        end
      throw(ArgumentError("No image selected"))
  end
  
function execute_process(user_model,pipeline,node,inputs::Vector)

    process = node.process
    @info "execute "*string(process.name)*" with $(length(inputs)) args"
    

    if (process.user_param_modifier!==nothing)
        process.user_param_modifier(user_model,pipeline.name*"_"*process.name,inputs...)
    end

    param = param_generator(user_model,pipeline.name,process.name,process.Param)

    if(node.cached.param!=param)
      node.cached.is_dirty=true
    end

    if !node.cached.is_dirty
      return node.cached.data
    end
    @info "$(pipeline.name) node $(node.process.name) is dirty reompute it "

    @info param

    output = process.f(inputs...,param)
    @info "output in comuted"
    return output

end



function execute_node(user_model,pipeline,node::PipelineNode)


    inputs = []
    if isempty(node.inputs)
      
      zzinput = select_image(user_model)
      @info "The $(pipeline.name) need user input image "

      if(node.cached.input_key==zzinput.img_id)
        #if image do no change

        inputs= node.cached.input_value
      else
        node.cached.input_key=zzinput.img_id
        node.cached.is_dirty = true
        inputs = [load(zzinput.image_path)]
        node.cached.input_value = inputs
        @info "user input image loaded "
      end
    else
        for input_node in node.inputs
            if input_node.cached.is_dirty
                # if one of my chil is dirty so im I
                node.cached.is_dirty = true

                execute_node(user_model,pipeline,input_node)
            end
            push!(inputs,input_node.cached.data)
        end
    end


    output = execute_process(user_model,pipeline,node,inputs)
    node.cached.is_dirty=false
    node.cached.data=output
    return output
end


  
  function execute_pipeline(user_model,pipeline,exec_node=nothing)

      @info "execute "*string(pipeline.name)
      if exec_node!== nothing
       @info "with process="*exec_node.process.name    
      end
    
      @info "Selected image :", user_model.selected_image[]
      output_to_keep  = nothing
      output_to_keep_name  = ""
      try
        out = nothing
        last_node = nothing
        for node in pipeline.nodes 
          out = execute_node(user_model,pipeline,node)
          @info "node compare" objectid(node) objectid(exec_node)
          if node === exec_node
              output_to_keep=out
              output_to_keep_name=node.process.name
          end
          last_node= node
        end
        if output_to_keep===nothing
          output_to_keep=out
          output_to_keep_name=""
        end
      catch e
        StippleUI.notify(user_model, "Error in pipeline : $e", :negative)

        if !(e isa ArgumentError)
          @error "Error in pipeline" exception=(e, catch_backtrace())
        end
        return nothing
      end

    try   
      zzinput = select_image(user_model)
    add_image_to_model(user_model,pipeline,output_to_keep_name,zzinput.img_id,zzinput.img_name,output_to_keep)
  
    catch e
      StippleUI.notify(user_model, "Error in add_image_to_model : $e", :negative)
      @error "add_image_to_model went wrong" exception=(e, catch_backtrace())
    end
  
    end
  
  function get_new_img_id_img_name(pipeline,process_name,old_img_id,old_name)
    pipeline_name = pipeline.name
    if pipeline.is_visual
      img_id   = old_img_id
      img_name = old_name
    else
      img_id   = pipeline_name*((process_name!="") ? ("_"*process_name*"_") : "")*"_of_"*old_img_id
      img_name = pipeline_name*((process_name!="") ? ("_"*process_name*"_") : "")*"_of_"*old_name
    end

    return (img_id,img_name)
  end
  function add_image_to_model(user_model,pipeline,process_name,old_img_id,old_name,image)
  

    img_id,img_name= get_new_img_id_img_name(pipeline,process_name,old_img_id,old_name)


    filename = UPLOAD_PATH*img_id*"V.png"
    save(filename,image)
  
    @info "save $filename with $img_id"

    if haskey(user_model.list_image[],img_id)
      user_model.list_image[][img_id].image_version+=1
      if pipeline.is_visual
        user_model.list_image[][img_id].img_visual_path=filename
      else
        user_model.list_image[][img_id].image_path=filename
      end
    else
      user_model.list_image[][img_id] = ZzImage(img_id=img_id,image_path=filename,image_version=1,img_name=img_name)
    end
    # updat model on web
    push!(user_model,:list_image)

    end 

  
  function add_image_to_model(user_model,pipeline,process_name,old_img_id,old_name,data::Vector{PlotData})

    img_id,img_name= get_new_img_id_img_name(pipeline,process_name,old_img_id,old_name)

    if haskey(user_model.list_image[],img_id)
        user_model.list_image[][img_id].data=data
    else
      user_model.list_image[][img_id] = ZzPlot(img_id=img_id,data=data,img_name=img_name)
    end
    # updat model on web
    push!(user_model,:list_image)
  end