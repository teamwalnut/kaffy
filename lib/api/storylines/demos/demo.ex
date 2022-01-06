defmodule Api.Storylines.Demos.Demo do
  @moduledoc """
  Represents a demo
  which encapsulates an active demo version
  with its derivatives (guides, flow, etc.)
  """

  use Api.Schema

  schema "demos" do
    field(:name, :string)
    field(:last_played, :utc_datetime_usec)
    field(:is_shared, :boolean, null: false, default: true)
    field(:email_required, :boolean, null: false, default: false)
    field(:archived_at, :utc_datetime_usec, default: nil)
    has_many(:demo_version, Api.Storylines.Demos.DemoVersion)
    belongs_to(:active_version, Api.Storylines.Demos.DemoVersion)
    belongs_to(:storyline, Api.Storylines.Storyline)
    has_one(:company, through: [:storyline, :company])

    timestamps()
  end

  @doc false
  def changeset(demo, attrs) do
    demo
    |> cast(attrs, [:id, :name, :is_shared])
    |> validate_required([:name, :storyline_id, :active_version_id])
    |> assoc_constraint(:active_version)
    |> unique_constraint(:active_version_id)
    |> unsafe_validate_unique([:storyline_id, :name], Api.Repo,
      message: "can't have two demos with the same name value in a storyline"
    )
    |> unique_constraint([:storyline_id, :name], message: "Demo name must be unique per storyline")
  end

  @doc false
  def update_version_changeset(demo, attrs) do
    demo
    |> cast(attrs, [:active_version_id])
    |> validate_required([:active_version_id])
    |> unique_constraint(:active_version_id)
  end

  @doc false
  def rename_changeset(demo, attrs) do
    demo
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  @doc false
  def last_played_changeset(demo, attrs) do
    demo
    |> cast(attrs, [:last_played])
    |> validate_required([:last_played])
  end

  @doc false
  def update_changeset(demo, attrs) do
    demo
    |> cast(attrs, [:is_shared, :email_required, :archived_at])
  end

  @doc """
  Returns all demos by company_id and is_archived flag
  """
  def all_demos_query(company_id, member_id, is_archived \\ false) do
    # note(itay): This should return all the demos that I have access to
    # mimic'ing ApiWeb.Authorization.Demos
    q =
      from(demo in __MODULE__,
        join: company in assoc(demo, :company),
        join: storyline in assoc(demo, :storyline),
        join: owner in assoc(storyline, :owner),
        left_join: collaborators in assoc(storyline, :collaborators),
        where:
          company.id == ^company_id and
            is_nil(storyline.archived_at) and
            ((company.id == ^company_id and storyline.is_public == ^true) or
               collaborators.member_id == ^member_id or
               owner.id == ^member_id),
        order_by: [desc: demo.updated_at]
      )

    if is_archived do
      from(demo in q, where: not is_nil(demo.archived_at))
    else
      from(demo in q, where: is_nil(demo.archived_at))
    end
  end

  @doc """
  Returns all demos for a given storyline
  """
  def by_storyline_id_query(storyline_id, is_archived \\ false) do
    q =
      from(demo in __MODULE__,
        where: demo.storyline_id == ^storyline_id
      )

    if is_archived do
      from(demo in q, where: not is_nil(demo.archived_at))
    else
      from(demo in q, where: is_nil(demo.archived_at))
    end
  end

  def archived_query(company_id, member_id) do
    all_demos_query(company_id, member_id, true)
  end

  def archived_by_storyline_id_query(storyline_id) do
    by_storyline_id_query(storyline_id, true)
  end

  def ordered_query do
    from(demo in __MODULE__,
      order_by: [asc: demo.updated_at]
    )
  end
end
