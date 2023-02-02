using Logging

function metafmt(level::LogLevel, _module, group, id, file, line)
  @nospecialize
  color = Logging.default_logcolor(level)
  prefix = string(level == Warn ? "Warning" : string(level), ':')
  suffix::String = ""

  _module !== nothing && (suffix *= string(_module)::String)
  if file !== nothing
      _module !== nothing && (suffix *= " ")
      suffix *= Base.contractuser(file)::String
      if line !== nothing
          suffix *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
      end
  end
  #!isempty(suffix) && (suffix = "@ " * suffix)
  return color, suffix*" ] "*prefix, ""
end


if !isdefined(Main, Symbol("debug_logger"))
  debug_logger = ConsoleLogger(stderr, Logging.Info,meta_formatter=metafmt);
  global_logger(debug_logger)
end