using Logging
using Printf
"""
Defini un formater qui affiche le numero de ligne et le fichier pour tout les loglevel ! 
"""
function myformater(level::LogLevel, _module, group, id, file, line)
  @nospecialize
  color = Logging.default_logcolor(level)
  date_format = "HH:MM:SS.sss"
  prefix = string(level == Warn ? "Warning" : string(level), " $(Dates.format(Dates.now(), date_format)) ")
  suffix::String = ""

  _module !== nothing && (suffix *= string(_module)::String)
  if file !== nothing
      _module !== nothing && (suffix *= " ")
      suffix *= Base.contractuser(file)::String
      if line !== nothing
          suffix *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
      end
      suffix = @sprintf("%-70s",suffix)
  end
  #!isempty(suffix) && (suffix = "@ " * suffix)
  return color, prefix * suffix *" ] : ", ""
end




if !isdefined(Main, Symbol("zz_logger"))
  zz_logger = ConsoleLogger(stderr, Logging.Info,meta_formatter=myformater);
  global_logger(zz_logger)
end
