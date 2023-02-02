
## ZzView are item diplayed in WebUI
abstract type  ZzView

end


Base.@kwdef mutable struct ZzImage <: ZzView
    img_id::String =""
    image_path::String = ""
    image_version::Int = 0 # to force navigoator to reload image
  
    img_visual_path::String = ""
  
    img_name::String = ""
  
    rois::Dict{String,Any} = Dict{String,Any}()
    type = "ZzImage"
  end
  
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