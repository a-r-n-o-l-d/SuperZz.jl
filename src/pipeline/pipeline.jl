
abstract type AbstractParam end

lru_max_size = 10

# Pileline executor  
#
# 
# Stipple.@kwdef mutable struct Cache
#     is_dirty = true
#     param = nothing
#     data = nothing


#     input_key = nothing
#     input_value = nothing
# end




struct PipelineProcess
        name::String
        #descption::String
        f::Function
        Param::Any#DataType{AbstractParam}
        user_param_modifier::Union{Function,Nothing}
        PipelineProcess(n,fn,p,u=nothing) = new(n,fn,p,u)
end



function make_process(f::Function,fuser_param_modifier=nothing)
  param = Nothing
  for m in methods(f)
    if m.sig.parameters[end] <: AbstractParam
      if param == Nothing
        param=m.sig.parameters[end]
      elseif !(m.sig.parameters[end] isa param)
        throw("Process function must finish with the same AbstractParam type")
      end
    else
      @error m.sig
      throw("Process function must finis with AbstractParam type")
    end

  end
  PipelineProcess(string(Symbol(f)),f,param,fuser_param_modifier)
end



mutable struct PipelineNode
    inputs::Vector{Union{PipelineNode,Any}}
    process::PipelineProcess
    #cached::Cache
    is_dirty_passe::Bool
    cached_data::Any


    PipelineNode(i,p::PipelineProcess,c=true) = new(i,p,c)

    PipelineNode(i,p::Function) = new(i,make_process(p))
    PipelineNode(p::Function) = new([],make_process(p))

    PipelineNode(i,p::Function,f2::Function) = new(i,make_process(p,f2))
    PipelineNode(p::Function,f2::Function) = new([],make_process(p,f2))

end

#UserInputNode = PipelineNode([])
struct Pipeline

    name::String
    nodes::Vector{PipelineNode}
    is_visual::Bool

    Pipeline(n,ns,i=false) = new(n,ns,i)
    Pipeline(n,ns::PipelineNode) = new(n,[ns])
       
end


PLUGIN_DICT = Dict{String,Pipeline}()

function make_pipeline(node_fct::Function,name::String)
  global PLUGIN_DICT
  PLUGIN_DICT[name] = Pipeline(name,node_fct())
end

function single_process(f::Function,f2=nothing)
  make_pipeline(string(f)) do 
    PipelineNode([],make_process(f,f2))
  end
end


Stipple.@kwdef mutable struct InputImage{T}
  img_id::String = ""
  img_name::String = ""

  image::T = Nothing
  rois::Dict{String,Any} = Dict{String,Any}()
end

function Base.convert(::Type{InputImage},zzinput::ZzImage) 
  InputImage(;img_id=zzinput.img_id,img_name=zzinput.img_name,image=load_from_memory(zzinput.image_path),rois=zzinput.rois)
end

include("test_pipeline.jl")
include("visual_pipeline.jl")

function pipelines()
    return PLUGIN_DICT
  end

function all_pipeline()
  return pipelines()
  
end


function PipelineStructGenerator()  
    
    fields = [ ]
    for (key, pipe) in all_pipeline()
        for node in pipe.nodes 
            process= node.process
            fields_sub_type = flat_reactive_struct(process.Param,string(pipe.name)*"_"*string(process.name)*"_")
        
            push!(fields_sub_type,
             :($(Symbol(string(pipe.name)*"_"*string(process.name)*"_"*"execute"))::R{Bool} = false)
            )
            push!(fields,fields_sub_type...)
        end
        push!(fields,
        :($(Symbol(string(pipe.name)*"_"*"execute"))::R{Bool} = false)
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
    return pram
  end

  function param_seter(user_model,param,pipeline_name,process_name)

    flat_var_reactive_struct(
    user_model,
    param,
    pipeline_name*"_"*process_name*"_"
    )

  end
  
  


cache = LRU{Tuple{Any,Any},Any}(maxsize=lru_max_size)
input_cache = LRU{String,InputImage}(maxsize=lru_max_size)

function execute_process(user_model,pipeline,node,inputs::Vector,zzinput)

  process = node.process
  @info "execute "*string(process.name)*" with $(length(inputs)) args"

  if(isempty(inputs))
    @info "Selected image :", zzinput.img_id
    @info "The $(pipeline.name) need user input image "

    # only load image is not in cache
    inputs = [ get!(input_cache,zzinput.img_id) do 
      
      @warn hasmethod(convert,(Type{InputImage},typeof(zzinput)))
      if hasmethod(convert,(Type{InputImage},typeof(zzinput)))
        @info "user input image loaded "
        convert(InputImage,zzinput)
      else
        
        throw(ArgumentError("Image input not surported for now"))
      end



    end ]

    # update value if necesary
    if(inputs[1].img_name != zzinput.img_name )
      inputs[1].img_name = zzinput.img_name
    end
    
    if(inputs[1].rois != zzinput.rois )
        inputs[1].rois = zzinput.rois
    end

  end

  # first get param for cache
  param = param_generator(user_model,pipeline.name,process.name,process.Param)

  return get!(cache,(inputs,param)) do 

      @info "$(pipeline.name) node $(node.process.name) is dirty recompute it "
      @info "process process.user_param_modifier" process.user_param_modifier
      if (process.user_param_modifier!==nothing)
            process.user_param_modifier(user_model,pipeline.name*"_"*process.name,inputs...)
            @info "user_param_modifier is finish"
      end


      param_after_user_param_modifier = param_generator(user_model,pipeline.name,process.name,process.Param)
      output = process.f(inputs...,param_after_user_param_modifier)
      @info "output in comuted"
      return output 
  end

end



function execute_node(user_model,pipeline,node::PipelineNode,zzinput)


  if !node.is_dirty_passe
    return node.cached_data
  end
  # 

  inputs = []
  for input_node in node.inputs
            if input_node.is_dirty_passe
                # if one of my chil is dirty so im I
                node.is_dirty_passe = true

                execute_node(user_model,pipeline,input_node,zzinput)
            end
            push!(inputs,input_node.cached_data)
   end


    output = execute_process(user_model,pipeline,node,inputs,zzinput)
    node.is_dirty_passe =false
    node.cached_data =output
    return output
end


  
  function execute_pipeline(user_model,pipeline,exec_node=nothing,zzinput = nothing)
     
      if zzinput === nothing
        zzinput = zzview_select_by_user()
      end

      @info "execute "*string(pipeline.name)
      if exec_node!== nothing
       @info "with process="*exec_node.process.name    
      end
    

      output_to_keep  = nothing
      output_to_keep_name  = ""

      # reset node execution
      for node in pipeline.nodes 
        node.is_dirty_passe=true
      end

      try
        out = nothing
        last_node = nothing
        for node in pipeline.nodes 
          @info "test node" objectid(node)
          out = execute_node(user_model,pipeline,node,zzinput)
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
        if(length(pipeline.nodes)==1)
          output_to_keep_name=""
        end
      catch e

        StippleUI.notify(PLUGIN_ENV.user_model, "Error in pipeline : $e", :negative)

        if !(e isa ArgumentError)
          @error "Error in pipeline" exception=(e, catch_backtrace())
        end
        return nothing
      end

    try   
      if pipeline.is_visual
        nimg_id,nimg_name = zzinput.img_id,zzinput.img_name
      else
        nimg_id,nimg_name = derive_name(pipeline.name*((output_to_keep_name=="") ? ("_"*output_to_keep_name*"_") : ""),zzinput)
      end
      add_data_list(nimg_id,nimg_name,output_to_keep,pipeline.is_visual)
  
    catch e
      StippleUI.notify(PLUGIN_ENV.user_model, "Error in add_data_list : $e", :negative)
      @error "add_data_list went wrong" exception=(e, catch_backtrace())
    end
  
    end
  