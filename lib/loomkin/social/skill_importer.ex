defmodule Loomkin.Social.SkillImporter do
  @moduledoc """
  Imports skills from `.agents/skills/` directories into snippet records.
  """

  alias Loomkin.Social

  def import_from_disk(user, project_path) do
    skills_dir = Path.join(project_path, ".agents/skills")

    if File.dir?(skills_dir) do
      case File.ls(skills_dir) do
        {:ok, entries} ->
          entries
          |> Enum.filter(&File.dir?(Path.join(skills_dir, &1)))
          |> Enum.map(fn dir ->
            skill_path = Path.join([skills_dir, dir, "SKILL.md"])

            if File.exists?(skill_path) do
              case parse_skill_md(skill_path) do
                {:ok, {frontmatter, body}} ->
                  Social.create_snippet(user, %{
                    title: frontmatter["name"] || dir,
                    description: frontmatter["description"],
                    type: :skill,
                    content: %{"frontmatter" => frontmatter, "body" => body},
                    visibility: :private
                  })

                {:error, reason} ->
                  {:error, reason}
              end
            else
              {:error, :no_skill_md}
            end
          end)

        {:error, reason} ->
          {:error, {:ls_failed, reason}}
      end
    else
      {:error, :skills_dir_not_found}
    end
  end

  def parse_skill_md(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, parse_skill_content(content)}
      {:error, reason} -> {:error, {:read_failed, reason}}
    end
  end

  def parse_skill_content(content) do
    case String.split(content, ~r/^---\s*$/m, parts: 3) do
      [_before, yaml_str, body] ->
        frontmatter =
          case YamlElixir.read_from_string(yaml_str) do
            {:ok, map} when is_map(map) -> map
            _ -> %{}
          end

        {frontmatter, String.trim(body)}

      _ ->
        {%{}, String.trim(content)}
    end
  end
end
