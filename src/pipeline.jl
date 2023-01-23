
using Stipple
# Pileline executor  
#
# 


Stipple.@kwdef struct PipelineProcess
        name::String
        f::Function
        Inputs::Vector{DataType}
        Output::DataType
        Param::DataType
end

Stipple.@kwdef mutable struct Cache
    is_dirty = true
    data = nothing
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
       
end

include("test_pipeline.jl")

function pipelines()

    return Dict("croper"=>CropperPipeline)
  end

function PipelineStructGenerator()  
    
    fields = [ ]
    for (key, pipe) in pipelines()
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
    @info "param genrate"
    @info pram
    return pram
  end
  
  
  function select_image(user_model)
      for (k,v) in user_model.list_image[]
          if k==user_model.selected_image[]
              return v
          end
        end
  end
  

function execute_process(user_model,pipeline,process,inputs::Vector)
    @info "execute "*string(process.name)
    
    param = param_generator(user_model,pipeline.name,process.name,process.Param)

    @info param

    try
        output = process.f(inputs...,param)
        @info "output in comuted"
        return output
      catch e
        @error "process went wrong" exception=(e, catch_backtrace())
        return nothing
      end
end



function execute_node(user_model,pipeline,node::PipelineNode,image_inputs::Vector)

    # if !node.cached.is_dirty
    #     return node.output
    # end
    inputs = []
    if isempty(node.inputs)
        inputs = image_inputs
    else
        for input_node in node.inputs
            if input_node.cached.is_dirty
                execute_node(user_model,pipeline,input_node,image_inputs)
            end
            push!(inputs,input_node.cached.data)
        end
    end

    output = execute_process(user_model,pipeline,node.process,inputs)
    node.cached.is_dirty=false
    node.cached.data=output
    return output
end


  
  function execute_pipeline(user_model,pipeline,exec_node=nothing)

      @info "execute "*string(pipeline.name)* " with process="*exec_node.process.name    
    
      @info "Selected image :", user_model.selected_image[]
  

      zzinput = select_image(user_model)


    
      @info "zzinput ok "
      inputs = [load(zzinput.image_path)]
      @info "input in generate "
    
      output_to_keep  = nothing
      output_to_keep_name  = ""
      for node in pipeline.nodes 
        out = execute_node(user_model,pipeline,node,inputs)
        if node == exec_node
            output_to_keep=out
            output_to_keep_name=node.process.name
        end
      end
      if output_to_keep===nothing
        output_to_keep=out
        output_to_keep_name=node.process.name
      end

    try   
    add_image_to_model(user_model,string(pipeline.name)*"_"*output_to_keep_name*"_of_"*zzinput.img_id,output_to_keep)
  
    catch e
      @error "add_image_to_model went wrong" exception=(e, catch_backtrace())
    end
  
    end
  
  
  function add_image_to_model(user_model,img_id,image)
  
    filename = "/dev/shm/"*img_id*".png"
    save(filename,image)
  
    @info "save $filename with $img_id"
    user_model.list_image[][img_id] = ZzImage(img_id,filename)
    # updat model on web
    push!(user_model)

    end 