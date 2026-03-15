defmodule Loomkin.Schemas.Favorite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "favorites" do
    belongs_to :user, Loomkin.Accounts.User, type: :id
    belongs_to :snippet, Loomkin.Schemas.Snippet

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(user_id snippet_id)a

  def changeset(favorite, attrs) do
    favorite
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :snippet_id])
  end
end
