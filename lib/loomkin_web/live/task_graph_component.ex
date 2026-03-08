defmodule LoomkinWeb.TaskGraphComponent do
  @moduledoc "LiveComponent for interactive SVG task dependency graph visualization."

  use LoomkinWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       tasks: [],
       deps: [],
       positioned: [],
       edges: [],
       selected_node: nil,
       critical_path_edges: MapSet.new(),
       refresh_ref: nil,
       svg_width: 800,
       svg_height: 400
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-gray-950 text-gray-100">
      <div class="px-3 py-2.5 border-b border-gray-800">
        <h3 class="text-[10px] font-semibold text-gray-500 uppercase tracking-widest">
          Task Graph
        </h3>
      </div>
      <div class="flex-1 overflow-auto relative">
        <div class="flex flex-col items-center justify-center h-full px-6 text-center">
          <p class="text-gray-400 text-sm font-medium mb-1">No tasks yet</p>
        </div>
      </div>
    </div>
    """
  end
end
