defmodule Loomkin.Social.SkillInstaller do
  @moduledoc """
  Installs a snippet (type: :skill) to a project's `.agents/skills/` directory.
  """

  alias Loomkin.Schemas.Snippet

  def install_to_project(%Snippet{type: :skill} = snippet, project_path) do
    frontmatter = snippet.content["frontmatter"] || %{}
    body = snippet.content["body"] || ""
    name = frontmatter["name"] || snippet.slug || Snippet.slugify(snippet.title)

    dir = Path.join([project_path, ".agents/skills", name])

    with :ok <- File.mkdir_p(dir) do
      yaml_lines =
        frontmatter
        |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
        |> Enum.join("\n")

      content = "---\n#{yaml_lines}\n---\n\n#{body}\n"

      path = Path.join(dir, "SKILL.md")

      case File.write(path, content) do
        :ok -> {:ok, path}
        {:error, reason} -> {:error, {:write_failed, reason}}
      end
    else
      {:error, reason} -> {:error, {:mkdir_failed, reason}}
    end
  end

  def install_to_project(%Snippet{type: type}, _project_path) do
    {:error, {:wrong_type, type}}
  end
end
