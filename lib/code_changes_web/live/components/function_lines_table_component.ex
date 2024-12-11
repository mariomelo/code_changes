defmodule CodeChangesWeb.FunctionLinesTableComponent do
  use CodeChangesWeb, :live_component

  def update(assigns, socket) do
    total_changes = assigns.data
    |> Map.values()
    |> Enum.sum()

    data_with_percentages = assigns.data
    |> Enum.map(fn {lines, times_changed} ->
      percentage = if total_changes > 0, do: times_changed / total_changes * 100, else: 0
      {lines, times_changed, percentage}
    end)
    |> Enum.sort_by(fn {lines, _, _} -> lines end)

    {:ok,
     socket
     |> assign(:data_with_percentages, data_with_percentages)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Function Lines
            </th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Times Changed
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <%= for {lines, times_changed, percentage} <- @data_with_percentages do %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                <%= lines %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 relative">
                <div class="absolute inset-0 transition-all duration-500 ease-in-out bg-indigo-100"
                     style={"width: #{percentage}%"}>
                </div>
                <span class="relative z-10"><%= times_changed %></span>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
