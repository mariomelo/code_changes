defmodule CodeChanges.Github.Patch do
  defstruct [
    :parent_sha,
    :filename,
    :sizes_and_changes,
    :file_contents
]
end
