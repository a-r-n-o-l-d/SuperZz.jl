

# Stipple.@kwdef struct Input
#     image
# end

# Stipple.@kwdef struct Output 
#     image
# end


Stipple.@kwdef mutable struct RoiParam <: AbstractParam
    roi::Roi = Roi()
end

Stipple.@kwdef mutable struct NoParam <: AbstractParam
 
end

Stipple.@kwdef struct DimentionSlider
    v::Vector{Int} = [1]
    step_v::Vector{Int} = [1]
    min_v::Vector{Int} =  [1]
    max_v::Vector{Int} = [1]

end

Stipple.@kwdef mutable struct DimentionalParam  <: AbstractParam
    dimentions::DimentionSlider = DimentionSlider()
end
function erase_roi(input::InputImage,param::RoiParam)
    roi = input.rois[param.roi.name]
    @info "crop" input.rois[param.roi.name]

    x = trunc(Int,roi["x"]+1)
    x2 = x+ trunc(Int,roi["width"]+1)
    y = trunc(Int,roi["y"]+1)
    y2 = y+ trunc(Int,roi["height"]+1)
    input.image[y:y2,x:x2] .= 0
    return input.image
end
single_process(erase_roi)

function crop(input::InputImage,param::RoiParam)
    
    roi = input.rois[param.roi.name]
    @info "crop" input.rois[param.roi.name]

    x = trunc(Int,roi["x"]+1)
    x2 = x+ trunc(Int,roi["width"]+1)
    y = trunc(Int,roi["y"]+1)
    y2 = y+ trunc(Int,roi["height"]+1)
    return input.image[y:y2,x:x2]
    #return "test"
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end
single_process(crop)



function gray(input::InputImage,param::NoParam)
    return Gray.(input.image)
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end
single_process(gray)




function dimention(image::InputImage,param::DimentionalParam)

    @info "dimention test $(param.dimentions)"
    ima =  Base.view(image.image,:,:,param.dimentions.v...)
    @info "dimention test finish "
    return ima
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

function dimention_setter(user_model,flat_field,input::InputImage)

    image= input.image
    
    @info "dimention_setter : $(typeof(image))"

    flat_field = flat_field*"_"*"dimentions"

    values =  getfield(user_model,Symbol(flat_field*"_v"))

    min_field = getfield(user_model,Symbol(flat_field*"_min_v"))

    max_field = getfield(user_model,Symbol(flat_field*"_max_v"))


    min_field[]=[Tuple(first(CartesianIndices(axes(image)[3:end])))...]
    max_field[]=[Tuple(last(CartesianIndices(axes(image)[3:end])))...]
    getfield(user_model,Symbol(flat_field*"_step_v"))[]=[Tuple(step(CartesianIndices(axes(image)[3:end])))...]



    nva = vcat([v for v in values[] ] , [ 1 for _ in 1:(length(axes(image)[3:end])-length(values[])) ]  ) 
    resize!(nva,length(axes(image)[3:end])) 
    @warn nva "is strange"
    @debug max_field[] min_field[]
    @info "image exes" axes(image)
    nva = clamp.(nva,min_field[],max_field[])

    # update only if strictly needed
    @info "$(values[]) $nva"
    if values[] != nva
        values[]=nva
    end

    
    #push!(user_model)
end

single_process(dimention,dimention_setter)



function histogram(input::InputImage,param::NoParam)::Vector{PlotData}

    image= input.image
    hists = []
    for (comp, col) = zip([red, green, blue], [RGB(1,0,0), RGB(0,.8,0), RGB(0,0,1)])
        hist = fit(Histogram, reinterpret.(comp.(vec(image))), 0:256)
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

single_process(histogram)

Stipple.@kwdef mutable struct BinariseParam <: AbstractParam
    bin::Slider = Slider()
end
function binarise(input::InputImage,param::BinariseParam)
    img = Gray.(input.image)
    return img .> param.bin.v
    #return "test"
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

single_process(binarise)




