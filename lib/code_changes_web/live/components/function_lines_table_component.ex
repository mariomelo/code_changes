defmodule CodeChangesWeb.FunctionLinesTableComponent do
  use CodeChangesWeb, :live_component

  def update(assigns, socket) do
    max_line_count = case Map.keys(assigns.data) do
      [] -> 0
      keys -> Enum.max(keys)
    end

    # Calcular o total de ocorrências para percentuais
    total_occurrences = Enum.sum(Map.values(assigns.data))

    # Calcular percentuais para cada linha
    line_percentages = if total_occurrences > 0 do
      Map.new(1..max_line_count, fn line ->
        count = Map.get(assigns.data, line, 0)
        percentage = count * 100 / total_occurrences
        {line, percentage}
      end)
    else
      %{}
    end

    {:ok,
     socket
     |> assign(:line_counts, assigns.data)
     |> assign(:line_percentages, line_percentages)
     |> assign(:max_line_count, max_line_count)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <table class="min-w-full text-sm font-mono">
        <thead>
          <tr>
            <th class="text-left px-2 text-gray-600">Linhas</th>
            <th class="text-left px-2 text-gray-600">Ocorrências</th>
          </tr>
        </thead>
        <tbody>
          <%= if @max_line_count > 0 do %>
            <%= for line_count <- 1..@max_line_count do %>
              <tr class="hover:bg-gray-50">
                <td class="px-2 text-gray-800"><%= line_count %></td>
                <td class="px-2 text-gray-800 relative">
                  <div class="absolute inset-0 transition-all duration-500 ease-in-out bg-indigo-50"
                       style={"width: #{Map.get(@line_percentages, line_count, 0)}%"}>
                  </div>
                  <span class="relative z-10"><%= Map.get(@line_counts, line_count, 0) %></span>
                </td>
              </tr>
            <% end %>
          <% else %>
            <tr>
              <td colspan="2" class="px-2 text-gray-500 text-center">Nenhum dado disponível</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
