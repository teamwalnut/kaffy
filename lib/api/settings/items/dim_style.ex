defmodule Api.Settings.Items.DimStyle do
  @moduledoc """
  This module is not a complete "settings item". Instead it's a helper module to centralize logic around the dim_style
  setting that we have on Api.Settings.GuidesSettings, Api.Settings.StorylineGuidesSettings and Api.Settings.AnnotationSettings
  """
  def kinds do
    [:soft, :medium, :dark]
  end
end
