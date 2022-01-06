defmodule Api.Storylines.Storyline do
  @moduledoc """
  Stores attributes related to a single storyline. A storyline is like a template for a demo - It also contains Screens and various
  Attributes, the major difference is that a Demo can only be created from a Storyline, and multiple different Demos can be created
  from a single storyline.
  """
  use Api.Schema

  schema "storylines" do
    field(:last_edited, :utc_datetime_usec)
    field(:name, :string)
    field(:is_public, :boolean, default: false)
    field(:archived_at, :utc_datetime_usec, default: nil)

    embeds_one(:demo_flags, Api.Storylines.DemoFlags, on_replace: :delete)

    belongs_to(:start_screen, Api.Storylines.Screen)
    belongs_to(:owner, Api.Companies.Member)
    has_one(:company, through: [:owner, :company])
    has_many(:screens, Api.Storylines.Screen)
    has_many(:collaborators, Api.Storylines.Collaborator)
    has_many(:flows, Api.Storylines.ScreenGrouping.Flow)
    has_many(:patches, Api.Patching.Patch)
    has_many(:smart_object_classes, Api.Storylines.SmartObjects.Class)
    has_one(:default_flow, Api.Storylines.ScreenGrouping.Flow, where: [is_default: true])
    has_many(:guides, Api.Annotations.Guide)
    has_many(:demos, Api.Storylines.Demos.Demo)
    has_many(:variables, Api.Storylines.Demos.Variable)
    has_one(:settings, Api.Settings.StorylineSettings)

    timestamps()
  end

  @doc false
  def create_changeset(%__MODULE__{} = storyline, attrs) do
    storyline
    |> cast(attrs, [:name, :last_edited, :is_public])
    |> cast_embed(:demo_flags)
    |> put_embed(:demo_flags, %Api.Storylines.DemoFlags{})
    |> update_last_edited()
    |> validate_required([:name, :owner_id, :last_edited])
    |> foreign_key_constraint(:owner_id)
  end

  @doc false
  def update_changeset(%__MODULE__{} = storyline, attrs) do
    storyline
    |> cast(attrs, [:name, :start_screen_id, :is_public])
    |> update_last_edited()
    |> validate_required([:last_edited])
    |> foreign_key_constraint(:start_screen_id)
  end

  def archive_changeset(%__MODULE__{} = storyline) do
    storyline |> change(archived_at: DateTime.utc_now())
  end

  def restore_archived_changeset(%__MODULE__{} = storyline) do
    storyline |> change(archived_at: nil)
  end

  def private_storylines_query(owner_id, company_id) do
    from(storyline in all_storylines_query(owner_id, company_id),
      left_join: collabs in assoc(storyline, :collaborators),
      where:
        storyline.is_public == false and
          (storyline.owner_id == ^owner_id or collabs.member_id == ^owner_id)
    )
  end

  def public_storylines_query(company_id) do
    from(storyline in all_company_storylines_query(company_id),
      where: storyline.is_public == true
    )
  end

  def archived_storylines_query(owner_id, company_id) do
    from(storyline in all_company_storylines_query(company_id, true),
      where: storyline.owner_id == ^owner_id
    )
  end

  def all_storylines_query(member_id, company_id, is_archived \\ false) do
    from(storyline in all_company_storylines_query(company_id, is_archived),
      left_join: collabs in assoc(storyline, :collaborators),
      distinct: true,
      where:
        storyline.is_public == true or storyline.owner_id == ^member_id or
          collabs.member_id == ^member_id
    )
  end

  defp all_company_storylines_query(company_id, is_archived \\ false) do
    q =
      from(storyline in __MODULE__,
        join: company in assoc(storyline, :company),
        where: company.id == ^company_id,
        order_by: [desc: storyline.last_edited, desc: storyline.updated_at]
      )

    if is_archived do
      from(storyline in q, where: not is_nil(storyline.archived_at))
    else
      from(storyline in q, where: is_nil(storyline.archived_at))
    end
  end

  defp update_last_edited(changeset) do
    last_edited = changeset |> get_change(:last_edited)

    if last_edited == nil do
      changeset |> put_change(:last_edited, DateTime.utc_now())
    else
      changeset
    end
  end

  @doc false
  def last_edited_changeset(%__MODULE__{} = storyline, attrs) do
    storyline
    |> cast(attrs, [:last_edited])
    |> validate_required([:last_edited])
  end
end
