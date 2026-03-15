defmodule LoomkinWeb.SnippetLive do
  @moduledoc """
  Snippet detail, create, and edit views.

  Routes:
    - `/@:username/:slug` — show (public detail view)
    - `/snippets/new` — create
    - `/snippets/:id/edit` — edit
  """
  use LoomkinWeb, :live_view

  alias Loomkin.Repo
  alias Loomkin.Social
  alias Loomkin.Schemas.Snippet

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Snippet")}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"username" => username, "slug" => slug}) do
    snippet =
      Social.get_snippet_by_slug(username, slug)
      |> Repo.preload([:user, :forked_from])

    current_user =
      if socket.assigns[:current_scope],
        do: socket.assigns.current_scope.user,
        else: nil

    is_owner = current_user != nil and current_user.id == snippet.user_id
    is_favorited = current_user != nil and Social.favorited?(current_user, snippet)

    owner_username =
      if Ecto.assoc_loaded?(snippet.user),
        do: snippet.user.username,
        else: username

    forked_from_username =
      if snippet.forked_from_id && Ecto.assoc_loaded?(snippet.forked_from) && snippet.forked_from do
        forked = Repo.preload(snippet.forked_from, :user)

        if Ecto.assoc_loaded?(forked.user),
          do: forked.user.username,
          else: nil
      end

    socket
    |> assign(
      page_title: snippet.title,
      snippet: snippet,
      owner_username: owner_username,
      forked_from_username: forked_from_username,
      is_owner: is_owner,
      is_favorited: is_favorited
    )
  end

  defp apply_action(socket, :new, _params) do
    changeset = Snippet.changeset(%Snippet{}, %{})

    socket
    |> assign(
      page_title: "New Snippet",
      snippet: nil,
      form: to_form(changeset)
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    snippet = Social.get_snippet!(id)

    changeset =
      Snippet.changeset(snippet, %{})

    socket
    |> assign(
      page_title: "Edit #{snippet.title}",
      snippet: snippet,
      form: to_form(changeset)
    )
  end

  def handle_event("fork", _params, socket) do
    current_user = socket.assigns.current_scope.user
    snippet = socket.assigns.snippet

    case Social.fork_snippet(current_user, snippet) do
      {:ok, fork} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet forked!")
         |> push_navigate(to: ~p"/snippets/#{fork.id}/edit")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not fork snippet")}
    end
  end

  def handle_event("toggle_favorite", _params, socket) do
    current_user = socket.assigns.current_scope.user
    snippet = socket.assigns.snippet

    case Social.toggle_favorite(current_user, snippet) do
      {:ok, {:favorited, _}} ->
        {:noreply,
         assign(socket,
           is_favorited: true,
           snippet: %{snippet | favorite_count: snippet.favorite_count + 1}
         )}

      {:ok, :unfavorited} ->
        {:noreply,
         assign(socket,
           is_favorited: false,
           snippet: %{snippet | favorite_count: snippet.favorite_count - 1}
         )}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update favorite")}
    end
  end

  def handle_event("validate", %{"snippet" => params}, socket) do
    changeset =
      (socket.assigns.snippet || %Snippet{})
      |> Snippet.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"snippet" => params}, socket) do
    case socket.assigns.live_action do
      :new -> create_snippet(socket, params)
      :edit -> update_snippet(socket, params)
    end
  end

  defp create_snippet(socket, params) do
    current_user = socket.assigns.current_scope.user

    case Social.create_snippet(current_user, params) do
      {:ok, snippet} ->
        {:noreply,
         socket
         |> put_flash(:info, "Snippet created!")
         |> push_navigate(to: ~p"/@#{current_user.username}/#{snippet.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp update_snippet(socket, params) do
    snippet = socket.assigns.snippet

    case Social.update_snippet(snippet, params) do
      {:ok, updated} ->
        updated = Repo.preload(updated, :user)
        username = updated.user.username

        {:noreply,
         socket
         |> put_flash(:info, "Snippet updated!")
         |> push_navigate(to: ~p"/@#{username}/#{updated.slug}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def render(%{live_action: :show} = assigns) do
    ~H"""
    <div class="min-h-screen bg-surface-0 relative overflow-hidden">
      <div class="home-aurora" aria-hidden="true" />

      <nav class="relative z-20 border-b border-border-subtle bg-surface-0/80 backdrop-blur-md">
        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-14">
            <div class="flex items-center gap-3">
              <.link navigate={~p"/"} class="text-brand font-semibold text-lg tracking-tight">
                Loomkin
              </.link>
              <span class="text-gray-600">/</span>
              <.link
                navigate={~p"/@#{@owner_username}"}
                class="text-gray-400 text-sm hover:text-brand transition-colors"
              >
                @{@owner_username}
              </.link>
              <span class="text-gray-600">/</span>
              <span class="text-gray-200 text-sm font-medium">{@snippet.slug}</span>
            </div>
            <div class="flex items-center gap-2">
              <%= if @is_owner do %>
                <.link
                  navigate={~p"/snippets/#{@snippet.id}/edit"}
                  class="text-sm text-gray-400 hover:text-white transition-colors"
                >
                  Edit
                </.link>
              <% end %>
            </div>
          </div>
        </div>
      </nav>

      <div id="main-content" class="relative z-10 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 pb-16">
        <%!-- Snippet header --%>
        <div class="mb-8 animate-fade-in">
          <div class="flex items-start justify-between gap-4">
            <div>
              <h1 class="text-2xl font-semibold text-white">{@snippet.title}</h1>
              <p :if={@snippet.description} class="text-gray-400 text-sm mt-1">
                {@snippet.description}
              </p>
              <div class="flex items-center gap-3 mt-3">
                <span class={[
                  "inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium uppercase tracking-wider",
                  snippet_badge_class(to_string(@snippet.type))
                ]}>
                  {to_string(@snippet.type)}
                </span>
                <span class="text-gray-500 text-xs">
                  by
                  <.link
                    navigate={~p"/@#{@owner_username}"}
                    class="text-brand hover:text-violet-300 transition-colors"
                  >
                    @{@owner_username}
                  </.link>
                </span>
                <span
                  :if={@forked_from_username}
                  class="text-gray-600 text-xs flex items-center gap-1"
                >
                  <span class="hero-arrow-path-mini w-3 h-3" /> forked from @{@forked_from_username}
                </span>
              </div>
            </div>

            <%!-- Actions --%>
            <div class="flex items-center gap-2 shrink-0">
              <button
                phx-click="toggle_favorite"
                class={[
                  "flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm transition-all",
                  if(@is_favorited,
                    do: "bg-amber-500/15 text-amber-400 border border-amber-500/30",
                    else:
                      "bg-surface-2 text-gray-400 border border-border-subtle hover:border-border-hover hover:text-gray-300"
                  )
                ]}
              >
                <span class={[
                  "w-4 h-4",
                  if(@is_favorited, do: "hero-star-solid", else: "hero-star")
                ]} />
                {@snippet.favorite_count}
              </button>
              <button
                phx-click="fork"
                class={[
                  "flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm transition-all",
                  "bg-surface-2 text-gray-400 border border-border-subtle",
                  "hover:border-border-hover hover:text-gray-300"
                ]}
              >
                <span class="hero-arrow-path w-4 h-4" /> Fork ({@snippet.fork_count})
              </button>
            </div>
          </div>
        </div>

        <%!-- Content area --%>
        <div class="glass rounded-xl p-6 animate-fade-in" style="animation-delay: 50ms">
          <.snippet_content snippet={@snippet} />
        </div>

        <%!-- Tags --%>
        <div
          :if={@snippet.tags != []}
          class="flex items-center gap-2 mt-4 animate-fade-in"
          style="animation-delay: 100ms"
        >
          <span
            :for={tag <- @snippet.tags}
            class="text-xs text-gray-400 bg-surface-2 border border-border-subtle px-2 py-1 rounded-md"
          >
            {tag}
          </span>
        </div>
      </div>
    </div>
    """
  end

  def render(%{live_action: action} = assigns) when action in [:new, :edit] do
    ~H"""
    <div class="min-h-screen bg-surface-0 relative overflow-hidden">
      <div class="home-aurora" aria-hidden="true" />

      <nav class="relative z-20 border-b border-border-subtle bg-surface-0/80 backdrop-blur-md">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-14">
            <div class="flex items-center gap-3">
              <.link navigate={~p"/"} class="text-brand font-semibold text-lg tracking-tight">
                Loomkin
              </.link>
              <span class="text-gray-600">/</span>
              <span class="text-gray-300 text-sm font-medium">
                {if(@live_action == :new, do: "New Snippet", else: "Edit Snippet")}
              </span>
            </div>
          </div>
        </div>
      </nav>

      <div id="main-content" class="relative z-10 max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 pb-16">
        <h1 class="text-2xl font-semibold text-white mb-6 animate-fade-in">
          {if(@live_action == :new, do: "Create a Snippet", else: "Edit Snippet")}
        </h1>

        <.form
          for={@form}
          id="snippet-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6 animate-fade-in"
          style="animation-delay: 50ms"
        >
          <.input field={@form[:title]} label="Title" placeholder="My awesome skill..." />
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            placeholder="What does this snippet do?"
          />

          <div class="grid grid-cols-2 gap-4">
            <.input
              field={@form[:type]}
              type="select"
              label="Type"
              options={[
                {"Skill", "skill"},
                {"Prompt", "prompt"},
                {"Kin Agent", "kin_agent"},
                {"Chat Log", "chat_log"}
              ]}
            />
            <.input
              field={@form[:visibility]}
              type="select"
              label="Visibility"
              options={[
                {"Private", "private"},
                {"Unlisted", "unlisted"},
                {"Public", "public"}
              ]}
            />
          </div>

          <div class="flex items-center justify-end gap-3 pt-4">
            <.link
              navigate={~p"/"}
              class="px-4 py-2 text-sm text-gray-400 hover:text-gray-300 transition-colors"
            >
              Cancel
            </.link>
            <.button type="submit">
              {if(@live_action == :new, do: "Create Snippet", else: "Save Changes")}
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  attr :snippet, :map, required: true

  defp snippet_content(assigns) do
    content = assigns.snippet.content || %{}
    type = assigns.snippet.type
    assigns = assign(assigns, content: content, type: type)

    ~H"""
    <%= case @type do %>
      <% :chat_log -> %>
        <div class="space-y-3 max-h-[600px] overflow-y-auto">
          <%= for msg <- Map.get(@content, "messages", []) do %>
            <div class={[
              "rounded-lg px-3 py-2 text-sm",
              if(msg["role"] == "assistant",
                do: "bg-surface-2 text-gray-300",
                else: "bg-brand/10 text-gray-200"
              )
            ]}>
              <span class="text-xs font-medium text-gray-500 uppercase">{msg["role"]}</span>
              <p class="mt-1 whitespace-pre-wrap">{msg["content"]}</p>
            </div>
          <% end %>
        </div>
      <% _ -> %>
        <div class="chat-markdown">
          <pre class="text-gray-300 text-sm whitespace-pre-wrap"><%= cond do
            is_binary(@content) -> @content
            is_map(@content) -> Jason.encode!(@content, pretty: true)
            true -> inspect(@content)
          end %></pre>
        </div>
    <% end %>
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
end
