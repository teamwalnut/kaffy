defmodule Api.Repo.Migrations.AddAnnotationsStepConstraint do
  use Ecto.Migration

  def up do
    execute(
      "alter table annotations add constraint annotations_step_annotation_id unique(step, guide_id) deferrable initially immediate;"
    )
  end

  def down do
    execute("alter table annotations drop constraint annotations_step_annotation_id")
  end
end
