

# Stipple.@kwdef struct Input
#     image
# end

# Stipple.@kwdef struct Output 
#     image
# end


Stipple.@kwdef mutable struct CropParam <: Param
    roi::Roi = Roi()
end

Stipple.@kwdef mutable struct NoParam <: Param
 
end

Stipple.@kwdef struct DimentionSlider
    v::Vector{Int} = [1]
    step_v::Vector{Int} = [1]
    min_v::Vector{Int} =  [1]
    max_v::Vector{Int} = [1]

end

Stipple.@kwdef mutable struct DimentionalParam  <: Param
    dimentions::DimentionSlider = DimentionSlider()
end


function crop(input,param::CropParam)
    return input[1:500,1:500]
    #return "test"
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

CropperProcess= PipelineProcess("crop",crop,[Any],Any,CropParam)

function gray(input,param)
    return Gray.(input.image)
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

GrayVisualProcess = PipelineProcess("gray",gray,[Any],Any,NoParam)

function dimention(image,param)

    @info "dimention test $param.dimention"
    return image[:,:,param.dimentions.v...]
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

function dimention_setter(user_model,flat_field,image)
    
    @info "dimention_setter : $(typeof(image))"

    flat_field = flat_field*"_"*"dimentions"

    values =  getfield(user_model,Symbol(flat_field*"_v"))

    min_field = getfield(user_model,Symbol(flat_field*"_min_v"))

    max_field = getfield(user_model,Symbol(flat_field*"_max_v"))

    min_field[]=[Tuple(first(CartesianIndices(axes(image)[3:end])))...]
    max_field[]=[Tuple(last(CartesianIndices(axes(image)[3:end])))...]
    getfield(user_model,Symbol(flat_field*"_step_v"))[]=[Tuple(step(CartesianIndices(axes(image)[3:end])))...]

    nva = vcat([v for v in values[] ] , [ 1 for _ in 1:(length(axes(image)[3:end])-length(values[])) ]  )  
    @warn nva "is strange"
    @info max_field[] min_field[]
    @info "image exes" axes(image)
    nva = clamp.(nva,min_field[],max_field[])

    # update only if strictly needed
    @info "$(values[]) $nva"
    if values[] != nva
        values[]=nva
    end

    
    #push!(user_model)
end

DimentionalProcess = PipelineProcess("dimention",dimention,[Any],Any,DimentionalParam,dimention_setter)

using Plots, StatsBase

function histogram(input,param)::Vector{PlotData}
    hists = []
    for (comp, col) = zip([red, green, blue], [RGB(1,0,0), RGB(0,.8,0), RGB(0,0,1)])
        hist = fit(Histogram, reinterpret.(comp.(vec(input))), 0:256)
        push!(hists,PlotData(
            x = collect(hist.edges[1]),
            y = hist.weights,
            plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
            name = "Historgram " * string(col),
            #marker = 
        ))
        
    end

    return hists
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

histogramProcess = PipelineProcess("histogram",histogram,[Any],Any,NoParam)



Stipple.@kwdef mutable struct BinariseParam <: Param
    bin::Slider = Slider()
end
function binarise(input,param::BinariseParam)
    img = Gray.(input)
    return img .> param.bin.v
    #return "test"
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end
binariseProcess = PipelineProcess("binarise",binarise,[Any],Any,BinariseParam)
binarisePipeline = Pipeline("binarise",[PipelineNode([],binariseProcess,nothing)],false)



DimentionalPipeline = Pipeline("Dimention",[PipelineNode([],DimentionalProcess,nothing)],false)


CropperPipeline = Pipeline("croper",[PipelineNode([],CropperProcess,nothing)],false)


histogramPipeline = Pipeline("histogram",[PipelineNode([],histogramProcess,nothing)],false)






