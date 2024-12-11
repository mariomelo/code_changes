defmodule CodeChangesWeb.AnalyzedChangesComponent do
  use CodeChangesWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="space-y-4">
        <h3 class="text-lg font-semibold text-gray-900">Analyzed Changes</h3>
        <%= for patch <- @patches do %>
          <div class="bg-gray-50 rounded-lg p-4">
            <h4 class="text-sm font-medium text-gray-900 mb-2">
              <%= patch.filename %>
              <span class="text-xs text-gray-500">(Parent SHA: <%= patch.parent_sha %>)</span>
            </h4>

            <div class="space-y-4">
              <%= if patch.sizes_and_changes do %>
                <div>
                  <h5 class="text-xs font-medium text-gray-700 mb-1">Function Changes:</h5>
                  <pre class="text-xs bg-gray-100 p-3 rounded overflow-x-auto"><code><%= inspect(patch.sizes_and_changes, pretty: true) %></code></pre>
                </div>
              <% end %>

              <%= if patch.file_contents do %>
                <div>
                  <h5 class="text-xs font-medium text-gray-700 mb-1">Original File Contents:</h5>
                  <pre class="text-xs bg-gray-100 p-3 rounded overflow-x-auto"><code><%= patch.file_contents %></code></pre>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
