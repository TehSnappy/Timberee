defmodule BadResult do
  defexception message: "bad parameters.",
               plug_status: 403
end

defmodule MatchResult do
  defexception message: "bad parameters.",
               plug_status: 403
end
