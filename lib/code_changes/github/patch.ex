defmodule CodeChanges.Github.Patch do
  defstruct [
    :parent_sha,
    :filename,
    :patches,
    :file_contents
]
end
