defmodule CodeChangesWeb.FunctionLinesTableComponent do
  use CodeChangesWeb, :live_component

  def update(assigns, socket) do
    total = Enum.sum(Map.values(assigns.line_counts))
    
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:total_count, total)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="min-w-full text-sm">
        <thead>
          <tr>
            <th class="text-left px-2 py-1 text-gray-600 w-32">Lines</th>
            <th class="text-left px-2 py-1 text-gray-600">Changes</th>
          </tr>
        </thead>
        <tbody>
          <%= for {lines, count} <- sort_by_lines(@line_counts) do %>
            <tr class="hover:bg-gray-50">
              <td class="px-2 py-1 text-gray-800 font-medium whitespace-nowrap"><%= lines %></td>
              <td class="px-2 py-1 text-gray-800 relative">
                <div class="absolute inset-0 transition-all duration-500 ease-in-out bg-indigo-50"
                     style={"width: #{format_percentage(count, @total_count)}%"}>
                </div>
                <span class="relative z-10 ml-1"><%= count %></span>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp sort_by_lines(line_counts) do
    line_counts
    |> Enum.sort_by(fn {lines, _count} -> lines end)
  end

  defp format_percentage(_count, 0), do: 0
  defp format_percentage(count, total) do
    percentage = count / total * 100
    percentage |> Float.round(1)
  end
end
