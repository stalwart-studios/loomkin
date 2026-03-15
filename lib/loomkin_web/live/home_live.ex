defmodule LoomkinWeb.HomeLive do
  @moduledoc """
  Social dashboard homepage for deployed (multi_tenant) mode.

  Displays the user's projects, snippet counts, favorites, and recent sessions
  on the left, with a community feed and trending snippets on the right.

  In local mode, redirects to the project picker at `/projects`.
  """
  use LoomkinWeb, :live_view

  alias Loomkin.Repo
  alias Loomkin.Session.Persistence
  alias Loomkin.Social

  def mount(_params, _session, socket) do
    unless Application.get_env(:loomkin, :multi_tenant) do
      {:ok, push_navigate(socket, to: ~p"/projects")}
    else
      user = socket.assigns.current_scope && socket.assigns.current_scope.user
      projects = Persistence.list_projects()

      {snippet_counts, favorites, recent_sessions} =
        if user do
          counts = Social.snippet_counts_by_type(user)

          favs =
            Social.list_favorites(user, limit: 5)
            |> Enum.map(fn fav -> fav.snippet end)
            |> Repo.preload(:user)

          sessions = Persistence.list_sessions(limit: 5)

          {counts, favs, sessions}
        else
          {%{skills: 0, prompts: 0, kin_agents: 0, chat_logs: 0}, [], []}
        end

      community_feed =
        Social.list_public_snippets(limit: 10, sort: :recent)
        |> Repo.preload(:user)

      trending =
        Social.trending_snippets(limit: 5)
        |> Repo.preload(:user)

      socket =
        socket
        |> assign(
          page_title: "Home",
          snippet_counts: snippet_counts,
          favorites: favorites,
          community_feed: community_feed,
          trending: trending,
          recent_sessions: recent_sessions,
          greeting: time_greeting()
        )
        |> stream(:projects, projects, dom_id: &project_dom_id/1)

      {:ok, socket}
    end
  end

  defp project_dom_id(%{project_path: path}) do
    "home-project-" <> Base.url_encode64(path, padding: false)
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-surface-0 relative overflow-hidden">
      <%!-- Ambient background — aurora mesh --%>
      <div class="home-aurora" aria-hidden="true" />

      <%!-- Top nav bar --%>
      <.top_nav current_scope={assigns[:current_scope]} />

      <%!-- Main content --%>
      <div id="main-content" class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6 pb-16">
        <%!-- Greeting --%>
        <div class="mb-8 animate-fade-in">
          <h1 class="text-2xl font-semibold text-white tracking-tight">
            {@greeting}
          </h1>
          <p class="text-gray-500 text-sm mt-1">Your AI workspace at a glance</p>
        </div>

        <%!-- 2-Column layout --%>
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <%!-- Left column — Personal workspace --%>
          <div class="lg:col-span-5 space-y-6">
            <.projects_section projects={@streams.projects} />
            <.snippet_summary counts={@snippet_counts} />
            <.favorites_section favorites={@favorites} />
          </div>

          <%!-- Right column — Community --%>
          <div class="lg:col-span-7 space-y-6">
            <.community_feed_section feed={@community_feed} />
            <.trending_section trending={@trending} />
          </div>
        </div>

        <%!-- Recent sessions bar --%>
        <.recent_sessions_bar sessions={@recent_sessions} />
      </div>
    </div>
    """
  end

  # ── Top Navigation ──────────────────────────────────────────────

  attr :current_scope, :any, default: nil

  defp top_nav(assigns) do
    ~H"""
    <nav class="relative z-20 border-b border-border-subtle bg-surface-0/80 backdrop-blur-md">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-14">
          <div class="flex items-center gap-3">
            <span class="text-brand font-semibold text-lg tracking-tight">Loomkin</span>
            <span class="text-gray-600 text-xs font-mono hidden sm:inline">social</span>
          </div>
          <div class="flex items-center gap-4">
            <.link
              navigate={~p"/explore"}
              class="text-sm text-gray-400 hover:text-white transition-colors"
            >
              Explore
            </.link>
            <%= if @current_scope && @current_scope.user do %>
              <.link
                navigate={~p"/users/settings"}
                class={[
                  "flex items-center gap-2 px-3 py-1.5 rounded-lg",
                  "bg-surface-2 border border-border-subtle hover:border-border-hover",
                  "text-sm text-gray-300 hover:text-white transition-all"
                ]}
              >
                <span class="w-6 h-6 rounded-full bg-brand/20 border border-brand/30 flex items-center justify-center">
                  <span class="text-[10px] font-bold text-brand">
                    {String.first(@current_scope.user.username || @current_scope.user.email)
                    |> String.upcase()}
                  </span>
                </span>
                <span class="hidden sm:inline">
                  {@current_scope.user.username || "Account"}
                </span>
                <span class="hero-chevron-down-mini w-3.5 h-3.5 text-gray-500" />
              </.link>
            <% else %>
              <.link
                href={~p"/users/log-in"}
                class="text-sm text-gray-400 hover:text-white transition-colors"
              >
                Log in
              </.link>
            <% end %>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  # ── Projects Section ────────────────────────────────────────────

  attr :projects, :any, required: true

  defp projects_section(assigns) do
    ~H"""
    <section class="animate-fade-in" style="animation-delay: 50ms">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Your Projects</h2>
        <.link
          navigate={~p"/sessions/new"}
          class="text-xs text-brand hover:text-violet-300 transition-colors flex items-center gap-1"
        >
          <span class="hero-plus-mini w-3 h-3" /> New session
        </.link>
      </div>
      <div id="home-projects" phx-update="stream" class="space-y-2">
        <div class="hidden only:block text-center py-8">
          <p class="text-gray-500 text-sm">No projects yet</p>
          <p class="text-gray-600 text-xs mt-1">Start a session to see your projects here</p>
        </div>
        <.link
          :for={{id, project} <- @projects}
          id={id}
          navigate={~p"/sessions/new?#{%{project_path: project.project_path}}"}
          class={[
            "block glass rounded-lg p-3.5 group hover-lift press-down",
            "hover:border-border-hover transition-all"
          ]}
        >
          <div class="flex items-center justify-between">
            <div class="min-w-0 flex-1">
              <h3 class="text-white text-sm font-medium group-hover:text-brand transition-colors truncate">
                {Path.basename(project.project_path)}
              </h3>
              <p class="text-gray-600 text-xs mt-0.5 truncate font-mono">
                {project.project_path}
              </p>
            </div>
            <div class="flex items-center gap-3 shrink-0 ml-3">
              <span class="text-gray-500 text-xs tabular-nums">
                {project.session_count}
              </span>
              <span class="text-gray-600 text-xs">
                {format_relative_time(project.last_active_at)}
              </span>
              <span class="hero-chevron-right-mini w-3.5 h-3.5 text-gray-600 group-hover:text-gray-400 transition-colors" />
            </div>
          </div>
        </.link>
      </div>
    </section>
    """
  end

  # ── Snippet Summary ─────────────────────────────────────────────

  attr :counts, :map, required: true

  defp snippet_summary(assigns) do
    ~H"""
    <section class="animate-fade-in" style="animation-delay: 100ms">
      <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Your Snippets</h2>
      <div class="grid grid-cols-2 gap-2">
        <.snippet_type_card type="Skills" count={@counts.skills} icon="hero-bolt-mini" color="cyan" />
        <.snippet_type_card
          type="Prompts"
          count={@counts.prompts}
          icon="hero-chat-bubble-bottom-center-text-mini"
          color="amber"
        />
        <.snippet_type_card
          type="Kin Agents"
          count={@counts.kin_agents}
          icon="hero-cpu-chip-mini"
          color="violet"
        />
        <.snippet_type_card
          type="Chat Logs"
          count={@counts.chat_logs}
          icon="hero-document-text-mini"
          color="emerald"
        />
      </div>
    </section>
    """
  end

  attr :type, :string, required: true
  attr :count, :integer, required: true
  attr :icon, :string, required: true
  attr :color, :string, required: true

  defp snippet_type_card(assigns) do
    ~H"""
    <button class={[
      "glass rounded-lg p-3 text-left group hover-lift press-down",
      "hover:border-border-hover transition-all w-full"
    ]}>
      <div class="flex items-center gap-2.5">
        <div class={[
          "w-8 h-8 rounded-md flex items-center justify-center shrink-0",
          snippet_icon_bg(@color)
        ]}>
          <span class={[@icon, "w-4 h-4", snippet_icon_color(@color)]} />
        </div>
        <div class="min-w-0">
          <p class="text-white text-lg font-semibold tabular-nums leading-none">{@count}</p>
          <p class="text-gray-500 text-xs mt-0.5">{@type}</p>
        </div>
      </div>
    </button>
    """
  end

  defp snippet_icon_bg("cyan"), do: "bg-cyan-500/10"
  defp snippet_icon_bg("amber"), do: "bg-amber-500/10"
  defp snippet_icon_bg("violet"), do: "bg-violet-500/10"
  defp snippet_icon_bg("emerald"), do: "bg-emerald-500/10"

  defp snippet_icon_color("cyan"), do: "text-cyan-400"
  defp snippet_icon_color("amber"), do: "text-amber-400"
  defp snippet_icon_color("violet"), do: "text-violet-400"
  defp snippet_icon_color("emerald"), do: "text-emerald-400"

  # ── Favorites Section ───────────────────────────────────────────

  attr :favorites, :list, required: true

  defp favorites_section(assigns) do
    ~H"""
    <section class="animate-fade-in" style="animation-delay: 150ms">
      <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">Favorites</h2>
      <%= if @favorites == [] do %>
        <div class="glass rounded-lg p-4 text-center">
          <p class="text-gray-500 text-sm">No favorites yet</p>
          <p class="text-gray-600 text-xs mt-1">
            Star snippets from the community to save them here
          </p>
        </div>
      <% else %>
        <div class="space-y-1.5">
          <button
            :for={fav <- @favorites}
            class={[
              "w-full text-left glass rounded-lg px-3 py-2.5 group",
              "hover:border-border-hover transition-all flex items-center gap-2.5"
            ]}
          >
            <span class="hero-star-solid w-3.5 h-3.5 text-amber-400 shrink-0" />
            <div class="min-w-0 flex-1">
              <p class="text-gray-200 text-sm truncate group-hover:text-white transition-colors">
                {fav.title}
              </p>
              <p class="text-gray-600 text-xs">{to_string(fav.type)}</p>
            </div>
          </button>
        </div>
      <% end %>
    </section>
    """
  end

  # ── Community Feed ──────────────────────────────────────────────

  attr :feed, :list, required: true

  defp community_feed_section(assigns) do
    ~H"""
    <section class="animate-fade-in" style="animation-delay: 75ms">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Community</h2>
        <.link
          navigate={~p"/explore"}
          class="text-xs text-gray-500 hover:text-gray-300 transition-colors"
        >
          View all
        </.link>
      </div>
      <div class="space-y-3">
        <.feed_card :for={snippet <- @feed} snippet={snippet} />
      </div>
    </section>
    """
  end

  attr :snippet, :map, required: true

  defp feed_card(assigns) do
    username = if Ecto.assoc_loaded?(assigns.snippet.user), do: assigns.snippet.user.username, else: "unknown"
    assigns = assign(assigns, :username, username)

    ~H"""
    <div class={[
      "glass-subtle rounded-lg p-4 group hover:border-border-hover transition-all",
      "hover-lift"
    ]}>
      <div class="flex items-start gap-3">
        <%!-- Avatar --%>
        <div class="w-8 h-8 rounded-full bg-surface-3 border border-border-subtle flex items-center justify-center shrink-0">
          <span class="text-xs font-medium text-gray-400">
            {String.first(@username) |> String.upcase()}
          </span>
        </div>
        <%!-- Content --%>
        <div class="min-w-0 flex-1">
          <p class="text-sm text-gray-300">
            <span class="text-brand font-medium">@{@username}</span>
            <span class="text-gray-500"> published </span>
            <span class="text-white font-medium">{@snippet.title}</span>
          </p>
          <div class="flex items-center gap-3 mt-1.5">
            <.snippet_type_badge type={to_string(@snippet.type)} />
            <div class="flex items-center gap-2 text-gray-500 text-xs">
              <span class="flex items-center gap-1">
                <span class="hero-star-mini w-3 h-3" /> {@snippet.favorite_count}
              </span>
              <span class="flex items-center gap-1">
                <span class="hero-arrow-path-mini w-3 h-3" /> {@snippet.fork_count}
              </span>
            </div>
            <span class="text-gray-600 text-xs ml-auto">{format_relative_time(@snippet.inserted_at)}</span>
          </div>
          <p :if={@snippet.description} class="text-gray-500 text-xs mt-1.5 line-clamp-2">
            {@snippet.description}
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :type, :string, required: true

  defp snippet_type_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium uppercase tracking-wider",
      snippet_badge_class(@type)
    ]}>
      {@type}
    </span>
    """
  end

  defp snippet_badge_class("skill"), do: "bg-cyan-500/10 text-cyan-400 border border-cyan-500/20"

  defp snippet_badge_class("prompt"),
    do: "bg-amber-500/10 text-amber-400 border border-amber-500/20"

  defp snippet_badge_class("kin_agent"),
    do: "bg-violet-500/10 text-violet-400 border border-violet-500/20"

  defp snippet_badge_class("chat_log"),
    do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"

  defp snippet_badge_class(_), do: "bg-gray-500/10 text-gray-400 border border-gray-500/20"

  # ── Trending Section ────────────────────────────────────────────

  attr :trending, :list, required: true

  defp trending_section(assigns) do
    ~H"""
    <section class="animate-fade-in" style="animation-delay: 125ms">
      <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
        Trending This Week
      </h2>
      <div class="glass rounded-lg overflow-hidden divide-y divide-border-subtle">
        <.trending_row :for={{item, idx} <- Enum.with_index(@trending, 1)} item={item} rank={idx} />
      </div>
    </section>
    """
  end

  attr :item, :map, required: true
  attr :rank, :integer, required: true

  defp trending_row(assigns) do
    username = if Ecto.assoc_loaded?(assigns.item.user), do: assigns.item.user.username, else: "unknown"
    assigns = assign(assigns, :username, username)

    ~H"""
    <div class="flex items-center gap-3 px-4 py-3 hover:bg-surface-3/50 transition-colors group">
      <span class={[
        "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0",
        if(@rank <= 3, do: "bg-brand/15 text-brand", else: "bg-surface-3 text-gray-500")
      ]}>
        {@rank}
      </span>
      <div class="min-w-0 flex-1">
        <p class="text-sm text-gray-200 font-medium truncate group-hover:text-white transition-colors">
          {@item.title}
        </p>
        <p class="text-gray-600 text-xs">by @{@username}</p>
      </div>
      <.snippet_type_badge type={to_string(@item.type)} />
      <span class="flex items-center gap-1 text-amber-400/80 text-xs shrink-0">
        <span class="hero-star-solid w-3 h-3" /> {@item.favorite_count}
      </span>
    </div>
    """
  end

  # ── Recent Sessions Bar ─────────────────────────────────────────

  attr :sessions, :list, required: true

  defp recent_sessions_bar(assigns) do
    ~H"""
    <section :if={@sessions != []} class="mt-8 animate-fade-in" style="animation-delay: 200ms">
      <div class="divider-brand mb-4" />
      <div class="flex items-center gap-2 mb-3">
        <span class="hero-clock-mini w-3.5 h-3.5 text-gray-500" />
        <h2 class="text-xs font-semibold text-gray-400 uppercase tracking-wider">Recent Sessions</h2>
      </div>
      <div class="flex flex-wrap gap-2">
        <.link
          :for={session <- @sessions}
          navigate={~p"/sessions/#{session.id}"}
          class={[
            "inline-flex items-center gap-2 px-3 py-2 rounded-lg",
            "glass-subtle hover:border-border-hover transition-all",
            "text-sm text-gray-400 hover:text-white group"
          ]}
        >
          <span class={[
            "w-1.5 h-1.5 rounded-full shrink-0",
            if(session.status == :active, do: "bg-emerald-400", else: "bg-gray-600")
          ]} />
          <span class="truncate max-w-[200px]">{session.title || "Untitled"}</span>
          <span class="text-gray-600 text-xs shrink-0">{format_relative_time(session.updated_at)}</span>
        </.link>
      </div>
    </section>
    """
  end

  # ── Helpers ─────────────────────────────────────────────────────

  defp time_greeting do
    hour = DateTime.utc_now().hour

    cond do
      hour < 12 -> "Good morning"
      hour < 17 -> "Good afternoon"
      true -> "Good evening"
    end
  end

  defp format_relative_time(nil), do: ""

  defp format_relative_time(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end
end
