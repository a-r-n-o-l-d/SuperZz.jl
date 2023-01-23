

# Stipple.@kwdef struct Input
#     image
# end

# Stipple.@kwdef struct Output 
#     image
# end


Stipple.@kwdef mutable struct Param 
    roi::Roi = Roi()
    theata::Slider = Slider()
end

Stipple.@kwdef mutable struct NoParam 
 
end

Stipple.@kwdef mutable struct DimentionalParam 
    dimention::Slider = Slider(1)
end


function crop(input,param)
    return input[1:500,1:500]
    #return "test"
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

CropperProcess= PipelineProcess("crop",crop,[Any],Any,Param)

function gray(input,param)::Output
    return Output(image=Gray.(input.image))
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end

GrayVisualProcess = PipelineProcess("gray",gray,[Any],Any,NoParam)

function dimention(input,param)::Output
    return Output(image=input.image[:,:,param.dimention.v+1])
    #return Output(image=input.image[param.roi.y1:param.roi.y2,param.roi.x1:param.roi.x2])
end


DimentionalProcess = PipelineProcess("dimention",dimention,[Any],Any,DimentionalVisualParam)


CropperPipeline = Pipeline("croper",[PipelineNode([],CropperProcess,nothing)])






