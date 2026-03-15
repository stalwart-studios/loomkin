defmodule Loomkin.Social.SkillInstaller do
  @moduledoc """
  Installs a snippet (type: :skill) to a project's `.agents/skills/` directory.
  """

  alias Loomkin.Schemas.Snippet

  def install_to_project(%Snippet{type: :skill} = snippet, project_path) do
    frontmatter = snippet.content["frontmatter"] || %{}
    body = snippet.content["body"] || ""
    name = frontmatter["name"] || snippet.slug || slugify(snippet.title)

    dir = Path.join([project_path, ".agents/skills", name])
    File.mkdir_p!(dir)

    yaml_lines =
      frontmatter
      |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
      |> Enum.join("\n")

    content = "---\n#{yaml_lines}\n---\n\n#{body}\n"

    path = Path.join(dir, "SKILL.md")
    File.write!(path, content)

    {:ok, path}
  end

  def install_to_project(%Snippet{type: type}, _project_path) do
    {:error, {:wrong_type, type}}
  end

  defp slugify(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/[\s]+/, "-")
    |> String.trim("-")
  end
end
